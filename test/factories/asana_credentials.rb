FactoryBot.define do
  factory :asana_credential do
    association :user
    access_token { "test_access_token_#{SecureRandom.hex(16)}" }
    refresh_token { "test_refresh_token_#{SecureRandom.hex(16)}" }
    expires_at { 1.hour.from_now }

    trait :expired do
      expires_at { 1.hour.ago }
    end

    trait :expiring_soon do
      expires_at { 5.minutes.from_now }
    end

    trait :no_refresh_token do
      refresh_token { nil }
    end

    trait :long_lived do
      expires_at { 30.days.from_now }
    end
  end
end