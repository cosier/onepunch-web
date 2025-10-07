require 'rails_helper'

RSpec.describe Invitation, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:invited_by).class_name('User').optional }
  end

  describe 'validations' do
    let(:organization) { create(:organization) }
    subject { build(:invitation, organization: organization) }

    it { should validate_presence_of(:email) }

    it 'validates presence of token' do
      invitation = build(:invitation, token: nil)
      invitation.valid? # Trigger callback which generates token
      expect(invitation.token).to be_present
    end

    describe 'email format' do
      it 'accepts valid email addresses' do
        invitation = build(:invitation, email: 'user@example.com')
        expect(invitation).to be_valid
      end

      it 'rejects invalid email addresses' do
        invitation = build(:invitation, email: 'invalid-email')
        expect(invitation).not_to be_valid
        expect(invitation.errors[:email]).to be_present
      end
    end

    describe 'role inclusion' do
      it 'accepts valid roles' do
        %w[owner admin member].each do |role|
          invitation = build(:invitation, role: role)
          expect(invitation).to be_valid
        end
      end

      it 'rejects invalid roles' do
        invitation = build(:invitation, role: 'invalid_role')
        expect(invitation).not_to be_valid
        expect(invitation.errors[:role]).to be_present
      end
    end

    describe 'token uniqueness' do
      it 'validates uniqueness of token' do
        existing = create(:invitation)
        # Factory generates unique tokens, so we need to manually set duplicate
        duplicate = build(:invitation, token: existing.token)

        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:token]).to include('has already been taken')
      end
    end

    describe 'email_not_already_member' do
      let(:organization) { create(:organization) }
      let(:user) { create(:user, email: 'existing@example.com') }

      before do
        create(:membership, user: user, organization: organization)
      end

      it 'prevents inviting existing member' do
        invitation = build(:invitation, organization: organization, email: 'existing@example.com')

        expect(invitation).not_to be_valid
        expect(invitation.errors[:email]).to include('is already a member of this organization')
      end

      it 'allows inviting non-member' do
        invitation = build(:invitation, organization: organization, email: 'new@example.com')

        expect(invitation).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe 'generate_token' do
      it 'generates token on create' do
        invitation = build(:invitation, token: nil)
        invitation.save

        expect(invitation.token).to be_present
        expect(invitation.token.length).to be >= 32
      end

      it 'does not override existing token' do
        invitation = create(:invitation, token: 'custom-token')
        expect(invitation.token).to eq('custom-token')
      end
    end

    describe 'set_expiration' do
      it 'sets expires_at to 7 days from now on create' do
        invitation = nil
        travel_to Time.current do
          invitation = create(:invitation, expires_at: nil)
          expect(invitation.expires_at).to be_within(1.second).of(7.days.from_now)
        end
      end

      it 'does not override existing expires_at' do
        custom_expiration = 14.days.from_now
        invitation = create(:invitation, expires_at: custom_expiration)
        expect(invitation.expires_at.to_i).to eq(custom_expiration.to_i)
      end
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }

    describe '.pending' do
      it 'returns invitations without accepted_at' do
        pending = create(:invitation, organization: organization, accepted_at: nil)
        accepted = create(:invitation, organization: organization, accepted_at: 1.day.ago)

        expect(Invitation.pending).to include(pending)
        expect(Invitation.pending).not_to include(accepted)
      end
    end

    describe '.accepted' do
      it 'returns invitations with accepted_at' do
        pending = create(:invitation, organization: organization, accepted_at: nil)
        accepted = create(:invitation, organization: organization, accepted_at: 1.day.ago)

        expect(Invitation.accepted).to include(accepted)
        expect(Invitation.accepted).not_to include(pending)
      end
    end

    describe '.expired' do
      it 'returns invitations past expires_at' do
        expired = create(:invitation, organization: organization, expires_at: 1.day.ago)
        valid = create(:invitation, organization: organization, expires_at: 1.day.from_now)

        expect(Invitation.expired).to include(expired)
        expect(Invitation.expired).not_to include(valid)
      end
    end

    describe '.valid' do
      it 'returns pending invitations not expired' do
        valid = create(:invitation, organization: organization, accepted_at: nil, expires_at: 1.day.from_now)
        expired = create(:invitation, organization: organization, accepted_at: nil, expires_at: 1.day.ago)
        accepted = create(:invitation, organization: organization, accepted_at: 1.hour.ago, expires_at: 1.day.from_now)

        result = Invitation.valid
        expect(result).to include(valid)
        expect(result).not_to include(expired)
        expect(result).not_to include(accepted)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }

    describe '#accepted?' do
      it 'returns true when accepted_at is present' do
        invitation = create(:invitation, accepted_at: 1.day.ago)
        expect(invitation.accepted?).to be true
      end

      it 'returns false when accepted_at is nil' do
        invitation = create(:invitation, accepted_at: nil)
        expect(invitation.accepted?).to be false
      end
    end

    describe '#expired?' do
      it 'returns true when expires_at is in the past' do
        invitation = create(:invitation, expires_at: 1.day.ago)
        expect(invitation.expired?).to be true
      end

      it 'returns false when expires_at is in the future' do
        invitation = create(:invitation, expires_at: 1.day.from_now)
        expect(invitation.expired?).to be false
      end

      it 'returns false when expires_at is nil' do
        invitation = build(:invitation, expires_at: nil)
        expect(invitation.expired?).to be false
      end
    end

    describe '#still_valid?' do
      it 'returns true when not accepted and not expired' do
        invitation = create(:invitation, accepted_at: nil, expires_at: 1.day.from_now)
        expect(invitation.still_valid?).to be true
      end

      it 'returns false when accepted' do
        invitation = create(:invitation, accepted_at: 1.hour.ago, expires_at: 1.day.from_now)
        expect(invitation.still_valid?).to be false
      end

      it 'returns false when expired' do
        invitation = create(:invitation, accepted_at: nil, expires_at: 1.day.ago)
        expect(invitation.still_valid?).to be false
      end
    end

    describe '#accept!' do
      let(:user) { create(:user) }
      let(:inviter) { create(:user) }
      let(:invitation) { create(:invitation, organization: organization, role: 'member', invited_by: inviter) }

      it 'creates membership for user' do
        expect {
          invitation.accept!(user)
        }.to change { organization.memberships.count }.by(1)

        membership = organization.memberships.find_by(user: user)
        expect(membership).to be_present
        expect(membership.role).to eq('member')
      end

      it 'marks invitation as accepted' do
        travel_to Time.current do
          invitation.accept!(user)
          expect(invitation.reload.accepted_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'sets organization as current if user has none' do
        user.update(current_organization: nil)

        invitation.accept!(user)

        expect(user.reload.current_organization).to eq(organization)
      end

      it 'does not override user current_organization if already set' do
        other_org = create(:organization)
        user.update(current_organization: other_org)

        invitation.accept!(user)

        expect(user.reload.current_organization).to eq(other_org)
      end

      it 'returns false if already accepted' do
        invitation.update(accepted_at: 1.day.ago)

        result = invitation.accept!(user)

        expect(result).to be false
      end

      it 'returns false if expired' do
        invitation.update(expires_at: 1.day.ago)

        result = invitation.accept!(user)

        expect(result).to be false
      end

      it 'returns true on success' do
        result = invitation.accept!(user)
        expect(result).to be true
      end
    end

    describe '#invitation_url' do
      it 'generates URL with token' do
        invitation = create(:invitation)

        url = invitation.invitation_url

        expect(url).to include(invitation.token)
        expect(url).to include('accept')
      end
    end
  end

  describe 'business logic' do
    let(:organization) { create(:organization) }
    let(:admin) { create(:user) }

    it 'can be created by admin' do
      invitation = create(:invitation,
                         organization: organization,
                         email: 'newuser@example.com',
                         role: 'member',
                         invited_by: admin)

      expect(invitation).to be_valid
      expect(invitation.invited_by).to eq(admin)
    end

    it 'supports complete invitation workflow' do
      # Create invitation
      invitation = create(:invitation,
                         organization: organization,
                         role: 'admin',
                         invited_by: admin)

      expect(invitation.still_valid?).to be true

      # User accepts invitation (different email than invitation)
      new_user = create(:user)
      result = invitation.accept!(new_user)

      expect(result).to be true
      expect(invitation.accepted?).to be true
      expect(organization.users).to include(new_user)

      # Cannot accept again
      result = invitation.accept!(new_user)
      expect(result).to be false
    end
  end
end