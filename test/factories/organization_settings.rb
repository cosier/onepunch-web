FactoryBot.define do
  factory :organization_setting do
    association :organization
    invoice_prefix { "INV" }
    invoice_counter { 1 }
    default_hourly_rate { 100.0 }
    tax_rate { 0.0 }
    currency { "USD" }
    time_zone { "UTC" }
    date_format { "%Y-%m-%d" }
    notification_email { false }
    notification_slack { false }
  end
end
