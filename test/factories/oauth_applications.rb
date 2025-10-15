FactoryBot.define do
  factory :oauth_application do
    name { "MyString" }
    client_id { "MyString" }
    client_secret { "MyString" }
    redirect_uris { "MyText" }
    scopes { "MyText" }
    confidential { false }
    revoked { false }
    user_id { 1 }
  end
end
