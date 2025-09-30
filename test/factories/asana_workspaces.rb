FactoryBot.define do
  factory :asana_workspace do
    association :user
    sequence(:asana_gid) { |n| "workspace_gid_#{n}" }
    sequence(:name) { |n| "Workspace #{n}" }
    is_organization { false }
    last_synced_at { 1.hour.ago }

    trait :organization do
      is_organization { true }
      sequence(:name) { |n| "Organization Workspace #{n}" }
    end

    trait :recently_synced do
      last_synced_at { 5.minutes.ago }
    end

    trait :stale do
      last_synced_at { 2.days.ago }
    end

    trait :never_synced do
      last_synced_at { nil }
    end
  end
end