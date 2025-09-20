# Form object
# This object is created when thhe users wants a price quote for certain projects.
# To calcualte the price of a Project, we need to start a Benchmark Workflow on the
# Swarm Engine.
class Quote
  include ActiveModel::Model

  attr_accessor :project_settings

  def save
    @project_settings.each do |uuid, settings|
      project = Project.find_by(uuid: uuid)
      next if project.nil?

      # TODO: Make this cleaner
      project.start_benchmarking(settings: {
        output: { frame_range: { type: settings["frame_range_type"] } },
      })
    end
  end
end
