class OrganizationSetting < ApplicationRecord
  belongs_to :organization

  validates :invoice_prefix, presence: true
  validates :invoice_counter, presence: true, numericality: { greater_than_or_equal_to: 1 }
  validates :currency, presence: true
  validates :time_zone, presence: true
  validates :date_format, presence: true
  validates :tax_rate, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :default_hourly_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  after_create :increment_invoice_counter

  def next_invoice_number
    "#{invoice_prefix}-#{invoice_counter.to_s.rjust(5, '0')}"
  end

  def increment_invoice_counter
    increment!(:invoice_counter)
  end
end
