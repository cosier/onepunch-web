require 'rails_helper'

RSpec.describe Project, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:client).optional }
    it { should have_many(:time_entries).dependent(:destroy) }
    it { should have_many(:invoices).dependent(:nullify) }
    it { should have_one(:asana_project).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(active: 0, on_hold: 1, completed: 2, cancelled: 3) }
  end

  describe 'callbacks' do
    describe 'set_default_color' do
      it 'sets a random hex color before creation' do
        project = create(:project, color: nil)
        expect(project.color).to match(/^#[0-9a-f]{6}$/i)
      end

      it 'does not override existing color' do
        project = create(:project, color: '#FF5733')
        expect(project.color).to eq('#FF5733')
      end
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }

    describe '.active' do
      it 'returns non-archived projects with active status' do
        active_project = create(:project, organization: organization, archived: false, status: :active)
        archived_project = create(:project, organization: organization, archived: true, status: :active)
        on_hold_project = create(:project, organization: organization, archived: false, status: :on_hold)

        expect(Project.active).to include(active_project)
        expect(Project.active).not_to include(archived_project, on_hold_project)
      end
    end

    describe '.archived' do
      it 'returns only archived projects' do
        active_project = create(:project, organization: organization, archived: false)
        archived_project = create(:project, organization: organization, archived: true)

        expect(Project.archived).to include(archived_project)
        expect(Project.archived).not_to include(active_project)
      end
    end

    describe '.billable' do
      it 'returns projects with hourly_rate set' do
        billable_project = create(:project, organization: organization, hourly_rate: 100.0)
        non_billable_project = create(:project, organization: organization, hourly_rate: nil)

        expect(Project.billable).to include(billable_project)
        expect(Project.billable).not_to include(non_billable_project)
      end

      it 'includes projects with zero hourly_rate' do
        free_project = create(:project, organization: organization, hourly_rate: 0.0)
        expect(Project.billable).to include(free_project)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:user) { create(:user) }
    let(:project) { create(:project, organization: organization, hourly_rate: 100.0) }

    before do
      create(:membership, user: user, organization: organization)
    end

    describe '#total_hours' do
      it 'returns 0 when project has no time entries' do
        expect(project.total_hours).to eq(0)
      end

      it 'calculates total hours from all time entries' do
        # Create time entries with specific time ranges
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 1.hour.ago) # 1 hour
        create(:time_entry, project: project, user: user,
               started_at: 5.hours.ago, ended_at: 3.hours.ago) # 2 hours
        create(:time_entry, project: project, user: user,
               started_at: 6.hours.ago, ended_at: 5.5.hours.ago) # 0.5 hours

        expect(project.total_hours).to eq(3.5)
      end

      it 'converts seconds to hours with decimals' do
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 30.minutes.ago) # 1.5 hours

        expect(project.total_hours).to eq(1.5)
      end
    end

    describe '#total_revenue' do
      it 'returns 0 when hourly_rate is nil' do
        project.update(hourly_rate: nil)
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 1.hour.ago)

        expect(project.total_revenue).to eq(0)
      end

      it 'calculates revenue from total_hours and hourly_rate' do
        project.update(hourly_rate: 150.0)
        create(:time_entry, project: project, user: user,
               started_at: 3.hours.ago, ended_at: 1.hour.ago) # 2 hours

        expect(project.total_revenue.to_f).to eq(300.0) # 2 hours * $150
      end

      it 'handles fractional hours correctly' do
        project.update(hourly_rate: 100.0)
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 30.minutes.ago) # 1.5 hours

        expect(project.total_revenue.to_f).to eq(150.0) # 1.5 hours * $100
      end

      it 'returns 0 for project with no time entries' do
        expect(project.total_revenue).to eq(0)
      end
    end

    describe '#unbilled_hours' do
      it 'returns 0 when project has no time entries' do
        expect(project.unbilled_hours).to eq(0)
      end

      it 'counts only unbilled billable time entries' do
        create(:time_entry, project: project, user: user,
               started_at: 3.hours.ago, ended_at: 2.hours.ago,
               billable: true, billed: false) # 1 hour
        create(:time_entry, project: project, user: user,
               started_at: 5.hours.ago, ended_at: 3.hours.ago,
               billable: true, billed: true)  # 2 hours (billed)
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 1.5.hours.ago,
               billable: false, billed: false) # 0.5 hours (non-billable)

        expect(project.unbilled_hours).to eq(1.0)
      end

      it 'returns 0 when all billable entries are billed' do
        create(:time_entry, project: project, user: user,
               started_at: 2.hours.ago, ended_at: 1.hour.ago,
               billable: true, billed: true)

        expect(project.unbilled_hours).to eq(0)
      end

      it 'excludes non-billable time entries' do
        create(:time_entry, project: project, user: user,
               started_at: 3.hours.ago, ended_at: 1.hour.ago,
               billable: false, billed: false)

        expect(project.unbilled_hours).to eq(0)
      end
    end

    describe 'status transitions' do
      it 'can transition from active to on_hold' do
        project.update(status: :active)
        project.update(status: :on_hold)
        expect(project.status).to eq('on_hold')
      end

      it 'can transition from active to completed' do
        project.update(status: :active)
        project.update(status: :completed)
        expect(project.status).to eq('completed')
      end

      it 'can be cancelled' do
        project.update(status: :cancelled)
        expect(project.status).to eq('cancelled')
        expect(project.cancelled?).to be true
      end
    end

    describe 'archival' do
      it 'can be archived' do
        project.update(archived: true)
        expect(project.archived).to be true
        expect(Project.archived).to include(project)
      end

      it 'is excluded from active scope when archived' do
        project.update(archived: true, status: :active)
        expect(Project.active).not_to include(project)
      end
    end
  end
end