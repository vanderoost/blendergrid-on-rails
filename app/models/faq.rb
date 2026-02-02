class Faq < ApplicationRecord
  default_scope { order(clicks: :desc) }
end
