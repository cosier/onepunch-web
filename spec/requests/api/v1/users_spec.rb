require 'rails_helper'

RSpec.describe 'Users API', type: :request do
  let(:user) { create(:user, :with_organization) }
  let(:oauth_token) { create(:oauth_access_token, user: user) }
  let(:headers) { { 'Authorization' => "Bearer #{oauth_token.token}" } }

  describe 'GET /api/v1/users/me' do
    it 'returns current user data' do
      get '/api/v1/users/me', headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['data']['id']).to eq(user.id)
      expect(json['data']['email']).to eq(user.email)
    end

    it 'includes organizations array' do
      org = user.current_organization
      get '/api/v1/users/me', headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['organizations']).to be_an(Array)
      expect(json['data']['organizations'].map { |o| o['id'] }).to include(org.id)
    end

    it 'includes current_organization' do
      get '/api/v1/users/me', headers: headers

      json = JSON.parse(response.body)
      expect(json['data']['current_organization']).to be_present
      expect(json['data']['current_organization']['id']).to eq(user.current_organization.id)
    end

    it 'returns 401 without authentication' do
      get '/api/v1/users/me'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'wraps response in data envelope' do
      get '/api/v1/users/me', headers: headers

      json = JSON.parse(response.body)
      expect(json).to have_key('data')
      expect(json['data']).to be_a(Hash)
    end

    context 'with multiple organizations' do
      it 'includes all user organizations' do
        org1 = user.current_organization
        org2 = create(:organization)
        create(:membership, user: user, organization: org2)

        get '/api/v1/users/me', headers: headers

        json = JSON.parse(response.body)
        org_ids = json['data']['organizations'].map { |o| o['id'] }
        expect(org_ids).to include(org1.id, org2.id)
      end

      it 'includes user role in each organization' do
        org = user.current_organization
        # Update existing membership to admin role
        user.memberships.find_by(organization: org).update(role: :admin)

        get '/api/v1/users/me', headers: headers

        json = JSON.parse(response.body)
        org_data = json['data']['organizations'].find { |o| o['id'] == org.id }
        expect(org_data['role']).to eq('admin')
      end
    end

    context 'with user without current organization' do
      it 'includes null current_organization' do
        user.update(current_organization: nil)

        get '/api/v1/users/me', headers: headers

        json = JSON.parse(response.body)
        expect(json['data']['current_organization']).to be_nil
      end
    end
  end

  describe 'POST /api/v1/users/regenerate_token' do
    it 'returns deprecation notice' do
      post '/api/v1/users/regenerate_token', headers: headers

      expect(response).to have_http_status(:gone)
      json = JSON.parse(response.body)
      expect(json['error']).to include('deprecated')
    end

    it 'returns 401 without authentication' do
      post '/api/v1/users/regenerate_token'

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
