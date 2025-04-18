class ProjectSource < ApplicationRecord
  belongs_to :user
  has_many :projects
  has_many_attached :attachments

  accepts_nested_attributes_for :projects

  def start_projects(indices)
    projects_attributes = []
    indices.each do |index|
      main_blend_file = self.attachments[index.to_i].blob.filename.to_s
      name = File.basename(main_blend_file, ".blend")
      projects_attributes << {
        name:, main_blend_file:, uuid: SecureRandom.uuid }
    end
    self.projects_attributes = projects_attributes

    swarm_engine_service = SwarmEngineService.new()

    self.projects.each do |project|
      workflow = project.workflows.new(job_type: :integrity_check)
      swarm_engine_service.start_integrity_check_workflow(workflow)
    end
  end
end
