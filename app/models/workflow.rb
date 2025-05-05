class Workflow < ApplicationRecord
  enum :job_type, [ :integrity_check, :price_calculation, :render ]
  enum :status, [ :started, :finished, :failed ], default: :started
  attribute :timing, :json, default: {}

  belongs_to :project

  def finalize(result: nil, timing: nil)
    # TODO: Also make a state machine for workflow state?
    if self.finished?
      Rails.logger.warn "Workflow was already finished!"
      return
    end

    self.timing = timing or {}
    self.finished!
    self.save!

    project.finish(result: result)
  end
end
