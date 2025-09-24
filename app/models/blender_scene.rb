class BlenderScene < ApplicationRecord
  belongs_to :project

  store_accessor :frame_range, :type, :start, :end, :step, :single, prefix: true
end
