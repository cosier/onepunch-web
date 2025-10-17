# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Authentication", type: :request do
  let(:user) { create(:user) }
  let(:organization) { create(:organization) }

  before do
    user.organizations << organization
    user.update!(current_organization: organization)
  end

  describe "OAuth access token authentication" do
    let(:oauth_app) { create(:oauth_application) }
    let(:oauth_token) do
      create(:oauth_access_token,
        user: user,
        oauth_application: oauth_app,
        scopes: "api",
        expires_at: 2.hours.from_now)
    end

    context "with valid OAuth token" do
      it "authenticates successfully and returns 200" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{oauth_token.token}" }

        expect(response).to have_http_status(:ok)
        expect(response.content_type).to match(/application\/json/)

        json = JSON.parse(response.body)
        expect(json["data"]).to be_present
        expect(json["data"]["id"]).to eq(user.id)
        expect(json["data"]["email"]).to eq(user.email)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{oauth_token.token}" }
        end.not_to raise_error
      end

      it "updates last_used_at timestamp" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{oauth_token.token}" }
          oauth_token.reload
        end.to change(oauth_token, :last_used_at)
      end
    end

    context "with expired OAuth token" do
      let(:oauth_token) do
        create(:oauth_access_token,
          user: user,
          oauth_application: oauth_app,
          scopes: "api",
          expires_at: 1.hour.ago)
      end

      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{oauth_token.token}" }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to match(/expired/)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{oauth_token.token}" }
        end.not_to raise_error
      end
    end

    context "with revoked OAuth token" do
      let(:oauth_token) do
        create(:oauth_access_token,
          user: user,
          oauth_application: oauth_app,
          scopes: "api",
          revoked_at: 1.hour.ago)
      end

      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{oauth_token.token}" }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to match(/revoked/)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{oauth_token.token}" }
        end.not_to raise_error
      end
    end
  end

  describe "API token authentication (legacy)" do
    let(:api_token) do
      create(:api_token,
        user: user,
        name: "Test Token",
        expires_at: 30.days.from_now)
    end

    context "with valid API token" do
      it "authenticates successfully and returns 200" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{api_token.token}" }

        expect(response).to have_http_status(:ok)

        json = JSON.parse(response.body)
        expect(json["data"]["id"]).to eq(user.id)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{api_token.token}" }
        end.not_to raise_error
      end
    end

    context "with expired API token" do
      let(:api_token) do
        create(:api_token,
          user: user,
          name: "Expired Token",
          expires_at: 1.day.ago)
      end

      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{api_token.token}" }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to match(/expired/)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{api_token.token}" }
        end.not_to raise_error
      end
    end

    context "with revoked API token" do
      let(:api_token) do
        create(:api_token,
          user: user,
          name: "Revoked Token",
          revoked_at: 1.hour.ago)
      end

      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer #{api_token.token}" }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to match(/revoked/)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer #{api_token.token}" }
        end.not_to raise_error
      end
    end
  end

  describe "missing or invalid token" do
    context "with no Authorization header" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/me"

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me"
        end.not_to raise_error
      end
    end

    context "with invalid token format" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "InvalidFormat" }

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "InvalidFormat" }
        end.not_to raise_error
      end
    end

    context "with non-existent token" do
      it "returns 401 unauthorized" do
        get "/api/v1/users/me",
          headers: { "Authorization" => "Bearer nonexistent_token_12345" }

        expect(response).to have_http_status(:unauthorized)

        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "does not raise DoubleRenderError" do
        expect do
          get "/api/v1/users/me",
            headers: { "Authorization" => "Bearer nonexistent_token_12345" }
        end.not_to raise_error
      end
    end
  end

  describe "response format" do
    let(:oauth_token) do
      create(:oauth_access_token,
        user: user,
        oauth_application: create(:oauth_application),
        scopes: "api",
        expires_at: 2.hours.from_now)
    end

    it "wraps successful responses in data envelope" do
      get "/api/v1/users/me",
        headers: { "Authorization" => "Bearer #{oauth_token.token}" }

      json = JSON.parse(response.body)
      expect(json).to have_key("data")
      expect(json["data"]).to be_a(Hash)
      expect(json["data"]).to have_key("id")
      expect(json["data"]).to have_key("email")
      expect(json["data"]).to have_key("organizations")
    end

    it "returns error object for failures" do
      get "/api/v1/users/me",
        headers: { "Authorization" => "Bearer invalid_token" }

      json = JSON.parse(response.body)
      expect(json).to have_key("error")
      expect(json["error"]).to be_a(String)
    end
  end
end
