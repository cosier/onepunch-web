FactoryBot.define do
  factory :asana_task do
    association :time_entry, factory: :time_entry
    sequence(:asana_gid) { |n| "task_gid_#{n}" }
    sequence(:name) { |n| "Task #{n}" }
    sequence(:asana_project_gid) { |n| "project_gid_#{n}" }
    completed { false }
    due_date { 7.days.from_now.to_date }
    assignee_gid { "assignee_gid_#{SecureRandom.hex(8)}" }
    cached_project_name { "Test Project" }
    cached_workspace_name { "Test Workspace" }

    trait :unassigned do
      time_entry { nil }
    end

    trait :completed do
      completed { true }
      completed_at { 1.day.ago }
    end

    trait :overdue do
      due_date { 2.days.ago.to_date }
      completed { false }
    end

    trait :no_due_date do
      due_date { nil }
    end

    trait :unassigned_user do
      assignee_gid { nil }
    end

    trait :with_workspace_project_names do
      sequence(:cached_project_name) { |n| "Project #{n}" }
      sequence(:cached_workspace_name) { |n| "Workspace #{n}" }
    end
  end
end