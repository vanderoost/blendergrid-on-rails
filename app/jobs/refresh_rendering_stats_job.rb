class RefreshRenderingStatsJob < ApplicationJob
  queue_as :default

  def perform
    rendered_ids = Project.unscoped
      .where(status: :rendered)
      .select(:id)

    Project::Render
      .where(total_samples: nil)
      .where(project_id: rendered_ids)
      .find_each do |render|
        render.populate_stats!
      end
  end
end
