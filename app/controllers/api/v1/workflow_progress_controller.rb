class Api::V1::WorkflowProgressController < ApplicationController
  def update
    puts "UPDATING WORKFLOW PROGRESS"
    render json: { status: "all good" }
  end
end
