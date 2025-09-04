class Session < ApplicationRecord
  include Trackable

  belongs_to :user
end
