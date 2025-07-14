class Render < ActiveRecord::Base
  belongs_to :project
  has_one :workflow
end
