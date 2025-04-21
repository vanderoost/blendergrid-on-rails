class Workflow < ApplicationRecord
  enum :job_type, [ :integrity_check,  :price_calculation, :render ]
  enum :status, [ :started,  :finished, :failed ], default: :started

  belongs_to :project

  def finalize
    if self.finished?
      Rails.logger.warn "Workflow was already finished!"
      return
    end

    self.finished!
    Rails.logger.info "Workflow is finished!"

    # TODO: Pull the integrity check results form S3

    self.project.status = :waiting

    # Do a cable thing to the frontend

    self.project.save # TODO: Can we save both ath the same time?
    self.save
  end
end
