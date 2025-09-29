# app/models/membership.rb
class Membership < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :organization
  
  # Validations
  validates :user_id, uniqueness: { scope: :organization_id }
  
  # Enums
  enum :role, { member: 0, admin: 1, owner: 2 }
  
  # Callbacks
  before_create :set_joined_at
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
end
