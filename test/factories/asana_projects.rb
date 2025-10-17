FactoryBot.define do
  factory :asana_project do
    association :project
    association :asana_workspace
    sequence(:asana_gid) { |n| "project_gid_#{n}" }
    sequence(:name) { |n| "Asana Project #{n}" }
    last_synced_at { 1.hour.ago }

    trait :recently_synced do
      last_synced_at { 5.minutes.ago }
    end

    trait :stale do
      last_synced_at { 2.days.ago }
    end

    trait :never_synced do
      last_synced_at { nil }
    end

    trait :archived do
      archived { true }
    end
  end
end