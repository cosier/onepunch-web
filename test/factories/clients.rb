FactoryBot.define do
  factory :client do
    association :organization
    sequence(:name) { |n| "Client #{n}" }
    sequence(:email) { |n| "client#{n}@example.com" }

    trait :without_email do
      email { nil }
    end
  end
end