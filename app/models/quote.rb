# Form object
# This object is created when thhe users wants a price quote for certain projects.
# To calcualte the price of a Project, we need to start a Benchmark Workflow on the
# Swarm Engine.
class Quote
  include ActiveModel::Model

  attr_accessor :project_uuids

  def save
    @project_uuids.each do |uuid|
      project = Project.find_by(uuid: uuid)
      project.start_benchmarking if project.present? && !project.has_errors?
    end
  end
end
