require 'rails_helper'

RSpec.describe Organization, type: :model do
  describe 'associations' do
    it { should have_many(:memberships).dependent(:destroy) }
    it { should have_many(:users).through(:memberships) }
    it { should have_many(:projects).dependent(:destroy) }
    it { should have_many(:time_entries).through(:projects) }
    it { should have_many(:clients).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:destroy) }
    it { should have_many(:invitations).dependent(:destroy) }
    it { should have_one(:organization_setting).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:organization) }

    it { should validate_presence_of(:name) }

    # Note: slug presence is validated but generate_slug callback sets it from name
    # so we test the validation differently
    it 'validates slug presence when name is blank' do
      org = Organization.new(name: '', slug: '')
      expect(org).not_to be_valid
      expect(org.errors[:slug]).to include("can't be blank")
    end

    describe 'name uniqueness' do
      it 'validates uniqueness of name' do
        create(:organization, name: 'Acme Corp')
        duplicate_org = build(:organization, name: 'Acme Corp')

        expect(duplicate_org).not_to be_valid
        expect(duplicate_org.errors[:name]).to include('has already been taken')
      end
    end

    describe 'slug uniqueness' do
      it 'validates uniqueness of slug' do
        create(:organization, name: 'Acme Corp', slug: 'acme-corp')
        duplicate_org = build(:organization, name: 'Different Name', slug: 'acme-corp')

        expect(duplicate_org).not_to be_valid
        expect(duplicate_org.errors[:slug]).to include('has already been taken')
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_slug' do
      it 'generates slug from name before validation' do
        org = create(:organization, name: 'Test Organization')
        expect(org.slug).to eq('test-organization')
      end

      it 'handles special characters in name' do
        org = create(:organization, name: 'Test & Associates, LLC!')
        expect(org.slug).to eq('test-associates-llc')
      end

      it 'does not override existing slug' do
        org = create(:organization, name: 'Test Org', slug: 'custom-slug')
        expect(org.slug).to eq('custom-slug')
      end
    end

    describe 'set_default_settings' do
      it 'sets subscription_status to trial after creation' do
        org = create(:organization)
        expect(org.subscription_status).to eq('trial')
      end

      it 'sets trial_ends_at to 14 days from now' do
        travel_to Time.current do
          org = create(:organization)
          expect(org.trial_ends_at).to be_within(1.second).of(14.days.from_now)
        end
      end

      it 'does not override existing subscription_status' do
        org = create(:organization, subscription_status: 'active')
        expect(org.subscription_status).to eq('active')
      end
    end

    describe 'create_organization_setting' do
      it 'creates organization_setting after creation' do
        org = create(:organization)
        expect(org.organization_setting).to be_present
      end
    end
  end

  describe 'scopes' do
    describe '.onboarded' do
      it 'returns organizations that have been onboarded' do
        onboarded_org = create(:organization, onboarded_at: 1.day.ago)
        not_onboarded_org = create(:organization, onboarded_at: nil)

        expect(Organization.onboarded).to include(onboarded_org)
        expect(Organization.onboarded).not_to include(not_onboarded_org)
      end
    end

    describe '.in_trial' do
      it 'returns organizations with trial status' do
        trial_org = create(:organization, subscription_status: 'trial')
        active_org = create(:organization, subscription_status: 'active')

        expect(Organization.in_trial).to include(trial_org)
        expect(Organization.in_trial).not_to include(active_org)
      end
    end

    describe '.active' do
      it 'returns organizations with trial or active status' do
        trial_org = create(:organization, subscription_status: 'trial')
        active_org = create(:organization, subscription_status: 'active')
        expired_org = create(:organization, subscription_status: 'expired')

        active_orgs = Organization.active
        expect(active_orgs).to include(trial_org, active_org)
        expect(active_orgs).not_to include(expired_org)
      end
    end

    describe '.personal' do
      it 'returns only personal organizations' do
        personal_org = create(:organization, :personal)
        business_org = create(:organization, :business)

        expect(Organization.personal).to include(personal_org)
        expect(Organization.personal).not_to include(business_org)
      end
    end

    describe '.business' do
      it 'returns only business organizations' do
        personal_org = create(:organization, :personal)
        business_org = create(:organization, :business)

        expect(Organization.business).to include(business_org)
        expect(Organization.business).not_to include(personal_org)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization, name: 'Test Corp') }

    describe '#display_name' do
      it 'returns name for business organizations' do
        business_org = create(:organization, :business, name: 'Business Corp')
        expect(business_org.display_name).to eq('Business Corp')
      end

      it 'returns "Personal Org." for personal organizations' do
        personal_org = create(:organization, :personal, name: 'John Doe Personal')
        expect(personal_org.display_name).to eq('Personal Org.')
      end
    end

    describe '#owner' do
      it 'returns the user with owner role' do
        user = create(:user)
        create(:membership, user: user, organization: organization, role: :owner)

        expect(organization.owner).to eq(user)
      end

      it 'returns nil if no owner exists' do
        expect(organization.owner).to be_nil
      end
    end

    describe '#onboarded?' do
      it 'returns true when onboarded_at is present' do
        organization.update(onboarded_at: 1.day.ago)
        expect(organization.onboarded?).to be true
      end

      it 'returns false when onboarded_at is nil' do
        organization.update(onboarded_at: nil)
        expect(organization.onboarded?).to be false
      end
    end

    describe '#complete_onboarding!' do
      it 'sets onboarded_at to current time' do
        travel_to Time.current do
          organization.complete_onboarding!
          expect(organization.onboarded_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'marks organization as onboarded' do
        expect {
          organization.complete_onboarding!
        }.to change { organization.onboarded? }.from(false).to(true)
      end
    end

    describe '#add_member' do
      let(:user) { create(:user) }

      it 'creates a membership with default member role' do
        expect {
          organization.add_member(user)
        }.to change(organization.memberships, :count).by(1)

        membership = organization.memberships.last
        expect(membership.user).to eq(user)
        expect(membership.role).to eq('member')
      end

      it 'creates a membership with specified role' do
        organization.add_member(user, role: 'admin')

        membership = organization.memberships.last
        expect(membership.role).to eq('admin')
      end

      it 'sets joined_at timestamp' do
        travel_to Time.current do
          organization.add_member(user)
          membership = organization.memberships.last
          expect(membership.joined_at).to be_within(1.second).of(Time.current)
        end
      end
    end

    describe '#member_count' do
      it 'returns the number of members' do
        user1 = create(:user)
        user2 = create(:user)
        create(:membership, user: user1, organization: organization)
        create(:membership, user: user2, organization: organization)

        expect(organization.member_count).to eq(2)
      end

      it 'returns 0 for organization with no members' do
        expect(organization.member_count).to eq(0)
      end
    end

    describe '#active_projects_count' do
      it 'returns count of non-archived projects' do
        create(:project, organization: organization, archived: false)
        create(:project, organization: organization, archived: false)
        create(:project, organization: organization, archived: true)

        expect(organization.active_projects_count).to eq(2)
      end

      it 'returns 0 for organization with no active projects' do
        create(:project, organization: organization, archived: true)
        expect(organization.active_projects_count).to eq(0)
      end
    end

    describe '#trial?' do
      it 'returns true when subscription_status is trial' do
        organization.update(subscription_status: 'trial')
        expect(organization.trial?).to be true
      end

      it 'returns false for non-trial status' do
        organization.update(subscription_status: 'active')
        expect(organization.trial?).to be false
      end
    end

    describe '#trial_expired?' do
      it 'returns true when trial has expired' do
        organization.update(
          subscription_status: 'trial',
          trial_ends_at: 1.day.ago
        )
        expect(organization.trial_expired?).to be true
      end

      it 'returns false when trial has not expired' do
        organization.update(
          subscription_status: 'trial',
          trial_ends_at: 1.day.from_now
        )
        expect(organization.trial_expired?).to be false
      end

      it 'returns false when not in trial' do
        organization.update(subscription_status: 'active')
        expect(organization.trial_expired?).to be false
      end

      it 'returns false when trial_ends_at is nil' do
        organization.update(
          subscription_status: 'trial',
          trial_ends_at: nil
        )
        expect(organization.trial_expired?).to be false
      end
    end
  end
end