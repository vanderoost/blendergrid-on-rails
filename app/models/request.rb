class Request < ApplicationRecord
  belongs_to :trackable, polymorphic: true, optional: true
  belongs_to :user, optional: true
end
