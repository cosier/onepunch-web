FactoryBot.define do
  factory :project do
    association :organization
    sequence(:name) { |n| "Project #{n}" }
    color { "#6366F1" }
    hourly_rate { 100.0 }
    status { :active }

    trait :active do
      status { :active }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_client do
      association :client
    end

    trait :billable do
      hourly_rate { 150.0 }
    end

    trait :non_billable do
      hourly_rate { 0.0 }
    end
  end
end