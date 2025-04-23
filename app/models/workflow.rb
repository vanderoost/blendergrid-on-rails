class Workflow < ApplicationRecord
  enum :job_type, [ :integrity_check,  :price_calculation, :render ]
  enum :status, [ :started,  :finished, :failed ], default: :started

  belongs_to :project

  def finalize(result: nil)
    if self.finished?
      Rails.logger.warn "Workflow was already finished!"
      return
    end

    self.finished!
    Rails.logger.info "Workflow is finished!"

    Rails.logger.info "Result: " + result.inspect
    # TODO: Pull the integrity check results form S3

    self.project.status = :waiting

    if result
      if result[:settings]
        self.project.settings = result[:settings]
      end
      if result[:stats]
        self.project.stats = result[:stats]
      end
    end

    # Do a cable thing to the frontend

    self.project.save # TODO: Can we save both ath the same time?
    self.save
  end
end
