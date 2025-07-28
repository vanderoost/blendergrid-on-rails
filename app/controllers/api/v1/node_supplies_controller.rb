class Api::V1::NodeSuppliesController < Api::BaseController
  def update
    result = NodeSupply.upsert_all(
      collection_params,
      unique_by: :unique_node_supply_dimensions,
      record_timestamps: true
    )
    render json: { updated_ids: result.rows }
  end

  private
    def collection_params
      # TODO: Use params.expect() instead
      params.require(:node_supplies).map do |entry|
        entry.permit(
          :provider_id, :region, :zone, :type_name, :capacity, :millicents_per_hour
        )
      end
    end
end
