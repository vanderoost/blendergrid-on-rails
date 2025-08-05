class FrameRangeType
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string

  def name
    id.to_s.humanize.titleize
  end

  def self.all
    [ :image, :animation ].map { |id| new(id: id) }
  end
end
