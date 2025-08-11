require "aws-sdk-sns"

class SwarmEngine
  def initialize
    @account_id = Rails.configuration.aws[:account_id]
    @region = Rails.configuration.aws[:region]
    @swarm_engine_env = Rails.configuration.swarm_engine[:env]
  end

  def start_workflow(workflow)
    message = workflow.make_start_message

    client.publish(
      message: message.to_json,
      topic_arn: self.topic_arn,
      message_attributes: {
        event_type: { data_type: "String", string_value: "workflow_started" },
      }
    )
  end

  private
    def client
      @sns ||= Aws::SNS::Client.new
    end

    def topic_arn
      topic = "external-#{@swarm_engine_env}-topic"
      Rails.logger.debug "Topic: #{topic}"
      "arn:aws:sns:#{@region}:#{@account_id}:#{topic}"
    end
end
