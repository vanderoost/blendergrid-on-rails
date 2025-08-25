require "redcarpet"

class Article < ApplicationRecord
  include Trackable

  scope :draft, -> { where(published_at: nil) }
  scope :scheduled, -> { where("published_at > ?", Time.current) }
  scope :published, -> { where("published_at <= ?", Time.current) }

  belongs_to :user

  def to_param
    slug
  end

  def author_name
    user.name
  end

  def body_html
    markdown = Redcarpet::Markdown.new(MarkdownRenderer, autolink: true, tables: true)
    markdown.render(body)
  end
end
