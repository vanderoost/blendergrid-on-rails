class Workflow < ApplicationRecord
  enum :job_type, [ :integrity_check, :price_calculation, :render ]
  enum :status, [ :started,  :finished, :failed ], default: :started

  belongs_to :project

  def finalize(result: nil)
    if self.finished?
      # TODO: Also make a state machine for workflow state?
      Rails.logger.warn "Workflow was already finished!"
      return
    end

    self.finished!
    Rails.logger.info "Workflow is finished!"

    project.state.finish(result: result)

    self.save
  end
end
