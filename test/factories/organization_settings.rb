FactoryBot.define do
  factory :organization_setting do
    # NOTE: Organization auto-creates OrganizationSetting in after_create callback
    # So we just use the association which triggers the creation
    association :organization

    # Only override the fields we care about in tests if needed
    sequence(:invoice_prefix) { |n| "INV#{n}" }
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
