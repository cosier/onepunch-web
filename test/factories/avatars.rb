FactoryBot.define do
  factory :avatar do
    user { nil }
    source { 1 }
    source_url { "MyString" }
    processed_at { "2025-10-08 18:19:27" }
    active { false }
  end
end
