module RequestTracking
  extend ActiveSupport::Concern

  included do
    before_action :start_tracking_request
    after_action :finish_tracking_request

    rescue_from StandardError do |exception|
      Rails.logger.error("ERROR: #{exception.message}")
      Rails.logger.error("Request UUID: #{request.uuid}")
      status_code = (response.status >= 200 && response.status < 300) ? 500
        : response.status
      finish_tracking_request(status_code: status_code)
      raise exception
    end
  end

  private
    def start_tracking_request
      return if skip_request_tracking?

      Current.request_data = {
        created_at: Time.current,
        ip_address: request.remote_ip,
        method: request.method,
        path: request.path,
        url_params: request.query_parameters.presence,
        form_params: filtered_params.presence,
        controller: controller_name,
        action: action_name,
        referrer: request.referrer,
        user_agent: request.user_agent,
        visitor_id: cookies.permanent.encrypted[:_blendergrid_vid] ||= Random.uuid,
        uuid: request.uuid,
      }
    end

    def finish_tracking_request(status_code: nil)
      return if Current.request_data.blank?

      Current.request_data[:status_code] = status_code || response.status

      if Current.request_data.key?(:created_at)
        response_time = Time.current - Current.request_data[:created_at]
        Current.request_data[:response_time_ms] = response_time.in_milliseconds.round
      end

      TrackRequestJob.perform_later(
        user: Current.user,
        request_data: Current.request_data,
        events: Current.events,
      )
    end

    def filtered_params
      parameter_filter.filter(request.request_parameters.except(
        :controller, :action, :authenticity_token).select { |_, v|
          v.is_a?(String) ||
          v.is_a?(Numeric) ||
          v.is_a?(TrueClass) ||
          v.is_a?(FalseClass)
        }.to_h
      )
    end

    def parameter_filter
      @parameter_filter ||= ActiveSupport::ParameterFilter.new(
        Rails.application.config.filter_parameters
      )
    end

    def skip_request_tracking?
      excluded_by_controller? ||
      excluded_by_path? ||
      excluded_by_user_agent?
    end

    def excluded_by_controller?
      excluded_controllers = %w[
        ActiveStorage::BlobsController
        ActiveStorage::DiskController
        ActiveStorage::RepresentationsController
        Rails::HealthController
      ]

      self.class.name.in?(excluded_controllers)
    end

    def excluded_by_path?
      excluded_patterns = [
        %r{\.map$},
        %r{^/\.well-known},
        %r{^/admin},
        %r{^/assets},
        %r{^/cable},
        %r{^/health_check},
        %r{^/hotwire-spark},
        %r{^/rails/active_storage},
      ]

      excluded_patterns.any? { |pattern| request.path.match?(pattern) }
    end

    def excluded_by_user_agent?
      bot_patterns = [
        /BingBot/i,
        /GoogleBot/i,
      ]

      return false unless request.user_agent
      bot_patterns.any? { |pattern| request.user_agent.match?(pattern) }
    end
end
