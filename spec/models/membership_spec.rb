require 'rails_helper'

RSpec.describe Membership, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    subject { create(:membership) }

    it 'validates uniqueness of user_id scoped to organization_id' do
      existing_membership = create(:membership)
      duplicate_membership = build(:membership,
                                   user: existing_membership.user,
                                   organization: existing_membership.organization)

      expect(duplicate_membership).not_to be_valid
      expect(duplicate_membership.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user in different organizations' do
      user = create(:user)
      org1 = create(:organization)
      org2 = create(:organization)

      membership1 = create(:membership, user: user, organization: org1)
      membership2 = build(:membership, user: user, organization: org2)

      expect(membership2).to be_valid
    end

    it 'allows different users in same organization' do
      organization = create(:organization)
      user1 = create(:user)
      user2 = create(:user)

      membership1 = create(:membership, user: user1, organization: organization)
      membership2 = build(:membership, user: user2, organization: organization)

      expect(membership2).to be_valid
    end
  end

  describe 'enums' do
    it { should define_enum_for(:role).with_values(member: 0, admin: 1, owner: 2) }

    it 'can be created as member' do
      membership = create(:membership, role: :member)
      expect(membership.member?).to be true
    end

    it 'can be created as admin' do
      membership = create(:membership, role: :admin)
      expect(membership.admin?).to be true
    end

    it 'can be created as owner' do
      membership = create(:membership, role: :owner)
      expect(membership.owner?).to be true
    end
  end

  describe 'callbacks' do
    describe 'set_joined_at' do
      it 'sets joined_at before creation' do
        travel_to Time.current do
          membership = create(:membership, joined_at: nil)
          expect(membership.joined_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'does not override existing joined_at' do
        custom_time = 5.days.ago
        membership = create(:membership, joined_at: custom_time)
        expect(membership.joined_at).to be_within(1.second).of(custom_time)
      end
    end
  end

  describe 'business logic' do
    let(:user) { create(:user) }
    let(:organization) { create(:organization) }

    it 'connects user to organization' do
      membership = create(:membership, user: user, organization: organization)

      expect(user.organizations).to include(organization)
      expect(organization.users).to include(user)
    end

    it 'can be promoted from member to admin' do
      membership = create(:membership, user: user, organization: organization, role: :member)

      membership.update(role: :admin)

      expect(membership.admin?).to be true
    end

    it 'can be promoted from admin to owner' do
      membership = create(:membership, user: user, organization: organization, role: :admin)

      membership.update(role: :owner)

      expect(membership.owner?).to be true
    end

    it 'can be demoted from admin to member' do
      membership = create(:membership, user: user, organization: organization, role: :admin)

      membership.update(role: :member)

      expect(membership.member?).to be true
    end

    it 'removes user from organization when destroyed' do
      membership = create(:membership, user: user, organization: organization)

      membership.destroy

      expect(user.organizations).not_to include(organization)
    end
  end
end