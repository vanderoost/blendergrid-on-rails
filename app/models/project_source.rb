class ProjectSource < ApplicationRecord
  belongs_to :user
  has_many :projects
  has_many_attached :attachments

  accepts_nested_attributes_for :projects

  def start_projects(indices)
    indices.each do |index|
      filename = attachments[index.to_i].blob.filename.to_s
      name     = File.basename(filename, ".blend")

      projects.build(
        uuid: SecureRandom.uuid,
        name: name,
        main_blend_file: filename
      )
    end

    save!

    swarm_engine_service = SwarmEngineService.new
    projects.find_each do |project|
      workflow = project.workflows.create!(
        uuid: SecureRandom.uuid,
        job_type: :integrity_check
      )
      swarm_engine_service.start_integrity_check_workflow(workflow)
    end
  end
end
