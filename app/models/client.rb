class Client < ApplicationRecord
  belongs_to :organization
  has_many :projects, dependent: :nullify
  has_many :invoices, dependent: :destroy

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :active, -> { joins(:projects).where(projects: { archived: false }).distinct }

  def total_revenue
    invoices.paid.sum(:total)
  end

  def outstanding_amount
    invoices.unpaid.sum(:total)
  end
end