class BenchmarksController < ApplicationController
  include ProjectScoped

  allow_unauthenticated_access only: %i[ create ]

  def create
    @benchmark = @project.benchmarks.new(benchmark_params)
    if @benchmark.save
      redirect_back fallback_location: @project
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def benchmark_params
      params.expect(benchmark: [ :frame_range_type ])
    end
end
