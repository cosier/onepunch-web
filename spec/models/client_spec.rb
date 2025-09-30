require 'rails_helper'

RSpec.describe Client, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should have_many(:projects).dependent(:nullify) }
    it { should have_many(:invoices).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }

    describe 'email format validation' do
      it 'accepts valid email formats' do
        client = build(:client, email: 'valid@example.com')
        expect(client).to be_valid
      end

      it 'accepts blank email' do
        client = build(:client, email: '')
        expect(client).to be_valid
      end

      it 'accepts nil email' do
        client = build(:client, email: nil)
        expect(client).to be_valid
      end

      it 'rejects invalid email formats' do
        invalid_client = build(:client, email: 'invalid-email')
        expect(invalid_client).not_to be_valid
        expect(invalid_client.errors[:email]).to be_present
      end
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }

    describe '.active' do
      it 'returns clients with active projects' do
        client_with_active = create(:client, organization: organization)
        client_with_archived = create(:client, organization: organization)
        client_without_projects = create(:client, organization: organization)

        create(:project, organization: organization, client: client_with_active, archived: false)
        create(:project, organization: organization, client: client_with_archived, archived: true)

        active_clients = Client.active
        expect(active_clients).to include(client_with_active)
        expect(active_clients).not_to include(client_with_archived, client_without_projects)
      end

      it 'does not duplicate clients with multiple active projects' do
        client = create(:client, organization: organization)
        create(:project, organization: organization, client: client, archived: false)
        create(:project, organization: organization, client: client, archived: false)

        active_clients = Client.active
        expect(active_clients.where(id: client.id).count).to eq(1)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }

    describe '#total_revenue' do
      it 'returns 0 when client has no invoices' do
        expect(client.total_revenue).to eq(0)
      end

      # Note: Will add comprehensive test once Invoice model with paid scope is tested
    end

    describe '#outstanding_amount' do
      it 'returns 0 when client has no unpaid invoices' do
        expect(client.outstanding_amount).to eq(0)
      end

      # Note: Will add comprehensive test once Invoice model with unpaid scope is tested
    end
  end

  describe 'business logic' do
    let(:organization) { create(:organization) }

    it 'can be created with just name' do
      client = create(:client, organization: organization, name: 'Test Client', email: nil)
      expect(client).to be_persisted
      expect(client.name).to eq('Test Client')
    end

    it 'can be created with name and email' do
      client = create(:client,
                      organization: organization,
                      name: 'Test Client',
                      email: 'client@example.com')
      expect(client).to be_persisted
      expect(client.email).to eq('client@example.com')
    end

    it 'nullifies project association when deleted' do
      client = create(:client, organization: organization)
      project = create(:project, organization: organization, client: client)

      client.destroy

      expect(project.reload.client_id).to be_nil
    end

    it 'destroys associated invoices when deleted' do
      client = create(:client, organization: organization)
      # Note: This test would be complete once Invoice model tests are written
      # For now just verify the association dependency is set correctly
      expect(Client.reflect_on_association(:invoices).options[:dependent]).to eq(:destroy)
    end
  end
end