class Avatar < ApplicationRecord
  belongs_to :user
  has_one_attached :image

  enum :source, {
    uploaded: 0,
    google: 1,
    gravatar: 2
  }

  validates :source, presence: true
  validate :only_one_active_per_user

  scope :active, -> { where(active: true) }

  def activate!
    transaction do
      user.avatars.update_all(active: false)
      update!(active: true)
    end
  end

  def display_url
    if image.attached?
      image
    elsif source_url.present?
      source_url
    else
      gravatar_url
    end
  end

  private

  def only_one_active_per_user
    if active? && user&.avatars&.active&.where&.not(id: id)&.exists?
      errors.add(:active, "can only have one active avatar per user")
    end
  end

  def gravatar_url
    email_hash = Digest::MD5.hexdigest(user.email.downcase.strip)
    "https://www.gravatar.com/avatar/#{email_hash}?d=mp&s=200"
  end
end