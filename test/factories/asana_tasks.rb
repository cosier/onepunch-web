FactoryBot.define do
  factory :asana_task do
    time_entry { nil }
    asana_gid { "MyString" }
    name { "MyString" }
    asana_project_gid { "MyString" }
    completed { false }
    due_date { "2025-09-30" }
    assignee_gid { "MyString" }
  end
end
