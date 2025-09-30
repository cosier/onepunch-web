class Invoice < ApplicationRecord
  belongs_to :organization
  belongs_to :client
  belongs_to :project, optional: true
  has_many :line_items, class_name: "InvoiceLineItem", dependent: :destroy
  has_one_attached :pdf

  validates :number, presence: true, uniqueness: { scope: :organization_id }
  validates :issued_at, presence: true
  validates :due_at, presence: true

  enum :status, { draft: 0, sent: 1, paid: 2, overdue: 3, cancelled: 4 }

  scope :unpaid, -> { where(status: [:sent, :overdue]) }

  before_validation :generate_number, on: :create
  before_save :calculate_totals

  def mark_as_paid!
    update!(status: :paid, paid_at: Time.current)
  end

  def overdue?
    due_at < Date.current && !paid?
  end

  private

  def generate_number
    return if number.present?
    return unless organization

    last_number = organization.invoices.maximum(:number)&.to_i || 0
    self.number = format("INV-%04d", last_number + 1)
  end

  def calculate_totals
    self.subtotal = line_items.sum(&:amount)
    self.tax_amount = subtotal * (tax_rate || 0) / 100.0
    self.total = subtotal + tax_amount
  end
end