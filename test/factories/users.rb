FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:first_name) { |n| "First#{n}" }
    sequence(:last_name) { |n| "Last#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :user }

    trait :admin do
      role { :admin }
    end

    trait :super_admin do
      role { :super_admin }
    end

    trait :with_google_oauth do
      google_uid { SecureRandom.hex(16) }
      password { nil }
      password_confirmation { nil }
    end

    trait :with_current_organization do
      after(:create) do |user|
        org = FactoryBot.create(:organization, :personal)
        FactoryBot.create(:membership, user: user, organization: org, role: :owner)
        user.update(current_organization: org)
      end
    end

    # Alias for common usage
    trait :with_organization do
      after(:create) do |user|
        org = FactoryBot.create(:organization, :personal)
        FactoryBot.create(:membership, user: user, organization: org, role: :owner)
        user.update(current_organization: org)
      end
    end
  end
end