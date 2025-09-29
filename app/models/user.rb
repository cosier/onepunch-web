# app/models/user.rb
class User < ApplicationRecord
  has_secure_password
  
  # Associations
  has_many :memberships, dependent: :destroy
  has_many :organizations, through: :memberships
  has_many :time_entries, dependent: :destroy
  
  # Validations
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, presence: true
  validates :last_name, presence: true
  
  # Enums
  enum :role, { user: 0, admin: 1, super_admin: 2 }
  
  # Callbacks
  before_save :downcase_email
  
  # Scopes
  scope :active, -> { where(last_sign_in_at: 30.days.ago..) }
  
  # Instance methods
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end
  
  def current_organization
    organizations.first # TODO: implement organization switching
  end
  
  # OAuth methods
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.google_uid = auth.uid
      user.first_name = auth.info.first_name
      user.last_name = auth.info.last_name
      user.avatar_url = auth.info.image
      user.password = SecureRandom.hex(16)
    end
  end
  
  private
  
  def downcase_email
    self.email = email.downcase
  end
end
