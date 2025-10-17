FactoryBot.define do
  factory :oauth_access_token do
    association :user
    association :oauth_application

    scopes { "api" }
    expires_at { 30.days.from_now }
    revoked_at { nil }  # Not revoked by default
    last_used_at { nil }

    # Let the model generate tokens via callbacks
    # token and refresh_token will be auto-generated
  end
end
