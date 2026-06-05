class Subscriber < ApplicationRecord
  include EmailValidatable

  belongs_to :user, optional: true

  # Lives here (not on User) so non-users can unsubscribe too. No expiry: links
  # must keep working however old the email is.
  generates_token_for :unsubscribe

  normalizes :guest_email_address, with: ->(e) { e.strip.downcase if e }

  # Guests carry their own email; user-linked rows derive it from the user.
  validates :guest_email_address, presence: true,
                                  uniqueness: { case_sensitive: false },
                                  format: EmailValidatable::VALID_EMAIL_REGEX,
                                  if: -> { user_id.blank? }

  # Soft delete == unsubscribed. Deliberately NOT a default_scope: the unsubscribe
  # flow and the guest-email uniqueness check both need to see unsubscribed rows.
  scope :subscribed, -> { where(deleted_at: nil) }

  # Find-or-initialize the subscription for an email — linked to a User when one
  # exists, otherwise a guest — and clear any prior unsubscribe (revive). NOT
  # saved, so callers can surface validation errors. This is the shared dedup
  # path for the newsletter form and the Kit import.
  def self.for_subscription(email:, name: nil, source: nil)
    email = email.to_s.strip.downcase
    user = User.find_by(email_address: email) if email.present?

    subscriber = user ? find_or_initialize_by(user: user)
                      : find_or_initialize_by(guest_email_address: email)
    subscriber.name = name if name.present? && subscriber.user.nil?
    subscriber.source ||= source
    subscriber.deleted_at = nil
    subscriber
  end

  # Trusted upsert for the one-off Kit import (active subscribers, valid emails).
  def self.import_from_kit(email:, first_name:, subscribed_at: nil)
    return if email.to_s.strip.blank?

    subscriber = for_subscription(email: email, name: first_name, source: "kit")
    subscriber.created_at ||= subscribed_at if subscribed_at.present?
    subscriber.save!
    subscriber
  end

  def email_address
    user ? user.email_address : guest_email_address
  end

  def name
    user&.name.presence || super
  end

  def subscribed?
    deleted_at.nil?
  end

  def unsubscribed?
    deleted_at.present?
  end

  def unsubscribe!
    update!(deleted_at: Time.current) if subscribed?
  end

  def subscribe!
    update!(deleted_at: nil) unless subscribed?
  end

  def greeting_name
    name.to_s.split.first.presence&.titleize || "there"
  end
end
