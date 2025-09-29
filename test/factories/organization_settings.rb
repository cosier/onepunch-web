FactoryBot.define do
  factory :organization_setting do
    organization { nil }
    invoice_prefix { "MyString" }
    invoice_counter { 1 }
    default_hourly_rate { "9.99" }
    tax_rate { "9.99" }
    currency { "MyString" }
    time_zone { "MyString" }
    date_format { "MyString" }
    notification_email { false }
    notification_slack { false }
  end
end
