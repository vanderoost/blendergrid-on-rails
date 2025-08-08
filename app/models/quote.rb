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
      project.benchmarks.create(settings: settings)
    end
  end
end
