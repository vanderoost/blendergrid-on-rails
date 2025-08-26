class Event < ApplicationRecord
  belongs_to :request
  belongs_to :resource, polymorphic: true
end
