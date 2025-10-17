FactoryBot.define do
  factory :summary do
    unique_slug { "MyString" }
    text_to_summarize { "MyText" }
    summarized_text { "MyText" }
    status { "MyString" }
  end
end
