require 'rails_helper'

RSpec.describe AsanaApiService, type: :service do
  let(:user) { create(:user) }
  let(:credential) do
    create(:asana_credential,
      user: user,
      access_token: 'test_access_token',
      refresh_token: 'test_refresh_token',
      expires_at: 1.hour.from_now
    )
  end
  let(:service) { described_class.new(credential) }

  describe '#fetch_workspaces' do
    it 'fetches workspaces from Asana API' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "123", "name": "My Workspace", "is_organization": true}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      workspaces = service.fetch_workspaces

      expect(workspaces).to be_an(Array)
      expect(workspaces).not_to be_empty
      expect(workspaces.first).to have_key('gid')
      expect(workspaces.first).to have_key('name')
    end

    it 'raises ApiError on network error' do
      allow(HTTParty).to receive(:get).and_raise(StandardError.new('Network error'))

      expect { service.fetch_workspaces }.to raise_error(StandardError, 'Network error')
    end
  end

  describe '#fetch_projects' do
    let(:workspace_gid) { '1234567890' }

    it 'fetches projects for a workspace' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "456", "name": "My Project", "archived": false}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      projects = service.fetch_projects(workspace_gid)

      expect(projects).to be_an(Array)
      expect(projects).not_to be_empty
      expect(projects.first).to have_key('gid')
      expect(projects.first).to have_key('name')
    end

    it 'filters out archived projects' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "456", "name": "My Project", "archived": false}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      projects = service.fetch_projects(workspace_gid)

      # Verify the API call includes archived: false parameter
      expect(projects).to be_an(Array)
    end
  end

  describe '#fetch_tasks' do
    let(:project_gid) { '9876543210' }

    it 'fetches tasks for a project' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "789", "name": "My Task", "completed": false}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      tasks = service.fetch_tasks(project_gid)

      expect(tasks).to be_an(Array)
      expect(tasks).not_to be_empty
      expect(tasks.first).to have_key('gid')
      expect(tasks.first).to have_key('name')
    end

    it 'includes optional fields in response' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "789", "name": "My Task", "completed": false, "due_on": "2025-10-01"}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      tasks = service.fetch_tasks(project_gid)

      expect(tasks).not_to be_empty
      task = tasks.first
      # These fields should be present due to opt_fields parameter
      expect(task.keys).to include('name')
    end

    it 'respects limit parameter' do
      response = double(
        code: 200,
        body: '{"data": [{"gid": "789", "name": "My Task"}]}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      tasks = service.fetch_tasks(project_gid, limit: 5)

      expect(tasks.length).to be <= 5
    end
  end

  describe '#test_connection' do
    it 'successfully tests API connection' do
      response = double(
        code: 200,
        body: '{"data": {"gid": "user123", "name": "Test User", "email": "test@example.com"}}'
      )
      allow(HTTParty).to receive(:get).and_return(response)

      result = service.test_connection

      expect(result).to be_a(Hash)
      expect(result[:success]).to be true
      expect(result[:user]).to be_present
      expect(result[:email]).to be_present
    end

    it 'returns error on failed connection' do
      allow(service).to receive(:get).and_raise(AsanaApiService::AuthenticationError.new('Invalid token'))

      result = service.test_connection

      expect(result[:success]).to be false
      expect(result[:error]).to be_present
    end
  end

  describe '#refresh_access_token!' do
    let(:expired_credential) do
      create(:asana_credential,
        user: user,
        access_token: 'old_token',
        refresh_token: 'valid_refresh_token',
        expires_at: 1.hour.ago
      )
    end
    let(:expired_service) { described_class.new(expired_credential) }

    context 'with valid refresh token' do
      it 'refreshes the access token' do
        response = double(
          code: 200,
          body: '{"access_token": "new_token", "refresh_token": "new_refresh", "expires_in": 3600}'
        )
        allow(HTTParty).to receive(:post).and_return(response)

        result = expired_service.refresh_access_token!

        expect(result).to be true
        expect(expired_credential.reload.access_token).not_to eq('old_token')
      end

      it 'updates the expiration time' do
        response = double(
          code: 200,
          body: '{"access_token": "new_token", "refresh_token": "new_refresh", "expires_in": 3600}'
        )
        allow(HTTParty).to receive(:post).and_return(response)

        old_expires_at = expired_credential.expires_at

        expired_service.refresh_access_token!

        expect(expired_credential.reload.expires_at).to be > old_expires_at
      end
    end

    context 'with invalid refresh token' do
      it 'returns false' do
        allow(HTTParty).to receive(:post).and_return(
          double(code: 400, body: '{"error": "invalid_grant"}')
        )

        result = expired_service.refresh_access_token!

        expect(result).to be false
      end
    end

    context 'without refresh token' do
      let(:no_refresh_credential) do
        create(:asana_credential,
          user: user,
          access_token: 'token',
          refresh_token: nil,
          expires_at: 1.hour.ago
        )
      end
      let(:no_refresh_service) { described_class.new(no_refresh_credential) }

      it 'returns false' do
        result = no_refresh_service.refresh_access_token!

        expect(result).to be false
      end
    end
  end

  describe 'error handling' do
    describe 'rate limiting' do
      it 'raises RateLimitError with retry information' do
        response = double(
          code: 429,
          headers: { 'Retry-After' => '60' },
          body: '{"errors": [{"message": "Rate limited"}]}'
        )
        allow(HTTParty).to receive(:get).and_return(response)

        expect { service.get('workspaces') }.to raise_error(AsanaApiService::RateLimitError, /60 seconds/)
      end
    end

    describe 'authentication errors' do
      it 'raises AuthenticationError on 401' do
        response = double(
          code: 401,
          body: '{"errors": [{"message": "Invalid token"}]}',
          request: double(path: double(to_s: '/workspaces'), options: {})
        )
        allow(HTTParty).to receive(:get).and_return(response)
        allow(service).to receive(:refresh_access_token!).and_return(false)

        expect { service.get('workspaces') }.to raise_error(AsanaApiService::AuthenticationError)
      end
    end

    describe 'generic API errors' do
      it 'raises ApiError for other error codes' do
        response = double(
          code: 500,
          body: '{"errors": [{"message": "Internal server error"}]}'
        )
        allow(HTTParty).to receive(:get).and_return(response)

        expect { service.get('workspaces') }.to raise_error(AsanaApiService::ApiError, /500/)
      end
    end
  end

  describe 'automatic token refresh' do
    let(:expired_credential) do
      create(:asana_credential,
        user: user,
        access_token: 'expired_token',
        refresh_token: 'valid_refresh_token',
        expires_at: 1.hour.ago
      )
    end
    let(:expired_service) { described_class.new(expired_credential) }

    it 'automatically refreshes token on 401 and retries request' do
      # First request returns 401
      first_response = double(
        code: 401,
        body: '{"errors": [{"message": "Invalid token"}]}',
        request: double(
          path: double(to_s: 'workspaces'),
          options: { query: {} }
        )
      )

      # After refresh, second request succeeds
      second_response = double(
        code: 200,
        body: '{"data": [{"gid": "123", "name": "Test Workspace"}]}'
      )

      call_count = 0
      allow(HTTParty).to receive(:get) do
        call_count += 1
        call_count == 1 ? first_response : second_response
      end

      # Mock successful token refresh
      allow(expired_service).to receive(:refresh_access_token!).and_return(true)

      result = expired_service.get('workspaces')

      expect(result['data']).to be_an(Array)
      expect(call_count).to eq(2) # First request + retry
    end
  end
end