 FactoryBot.define do
  factory :invitation do
    association :organization
    association :invited_by, factory: :user
    sequence(:email) { |n| "invite#{n}@example.com" }
    sequence(:token) { |n| "token-#{n}-#{SecureRandom.hex(8)}" }
    role { "member" }
    accepted_at { nil }
    expires_at { 7.days.from_now }

    trait :admin do
      role { "admin" }
    end

    trait :owner do
      role { "owner" }
    end

    trait :accepted do
      accepted_at { 1.day.ago }
    end

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :valid do
      accepted_at { nil }
      expires_at { 7.days.from_now }
    end
  end
end