class PageVariant < ApplicationRecord
  include Trackable
  belongs_to :landing_page
  has_many :users
end
