class Upload < ApplicationRecord
  has_one_attached :source_file
end
