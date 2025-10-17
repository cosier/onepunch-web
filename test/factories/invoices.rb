FactoryBot.define do
  factory :invoice do
    association :organization
    association :client
    project { nil }

    sequence(:number) { |n| "INV-#{n.to_s.rjust(4, '0')}" }
    issued_at { Date.current }
    due_at { 30.days.from_now }
    status { :draft }
    subtotal { 0.0 }
    tax_rate { 0.0 }
    tax_amount { 0.0 }
    total { 0.0 }

    trait :draft do
      status { :draft }
    end

    trait :sent do
      status { :sent }
    end

    trait :paid do
      status { :paid }
      paid_at { Time.current }
    end

    trait :overdue do
      status { :overdue }
      due_at { 10.days.ago }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :with_line_items do
      after(:create) do |invoice|
        create_list(:invoice_line_item, 3, invoice: invoice)
      end
    end
  end
end