FactoryBot.define do
  factory :time_entry do
    association :user
    association :project
    description { "Working on tasks" }
    started_at { 2.hours.ago }
    ended_at { 1.hour.ago }
    billable { true }

    trait :running do
      started_at { 1.hour.ago }
      ended_at { nil }
    end

    trait :stopped do
      started_at { 2.hours.ago }
      ended_at { 1.hour.ago }
    end

    trait :billable do
      billable { true }
    end

    trait :non_billable do
      billable { false }
    end

    trait :with_description do
      sequence(:description) { |n| "Task description #{n}" }
    end

    trait :today do
      started_at { Time.current.beginning_of_day + 9.hours }
      ended_at { Time.current.beginning_of_day + 10.hours }
    end

    trait :yesterday do
      started_at { 1.day.ago.beginning_of_day + 9.hours }
      ended_at { 1.day.ago.beginning_of_day + 10.hours }
    end
  end
end