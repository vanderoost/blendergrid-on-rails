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
    self.save
    Rails.logger.info "Workflow is finished!"

    # TODO: Pull the integrity check results form S3

    # Do a wire thing to the frontend
    self.project.status = :waiting
    self.project.save # TODO: Can we save both ath the same time?
  end
end
