FactoryBot.define do
  factory :organization do
    sequence(:name) { |n| "Organization #{n}" }
    personal { false }

    trait :personal do
      personal { true }
      sequence(:name) { |n| "Personal Org. #{n}" }
    end

    trait :business do
      personal { false }
    end

    trait :with_owner do
      after(:create) do |org|
        user = FactoryBot.create(:user)
        FactoryBot.create(:membership, user: user, organization: org, role: :owner)
      end
    end
  end
end