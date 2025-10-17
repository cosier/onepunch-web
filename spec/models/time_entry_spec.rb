require 'rails_helper'

RSpec.describe TimeEntry, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:project) }
    it { should have_one(:asana_task).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:started_at) }
  end

  describe 'callbacks' do
    describe 'calculate_duration' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }

      it 'calculates duration from started_at and ended_at' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 2.hours.ago,
                           ended_at: 1.hour.ago)

        expect(time_entry.duration).to eq(3600) # 1 hour in seconds
      end

      it 'does not set duration when ended_at is nil' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 1.hour.ago,
                           ended_at: nil)

        expect(time_entry.duration).to be_nil
      end

      it 'updates duration when times are changed' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 3.hours.ago,
                           ended_at: 2.hours.ago)

        time_entry.update(ended_at: 1.hour.ago)

        expect(time_entry.duration).to eq(7200) # 2 hours in seconds
      end
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    describe '.running' do
      it 'returns time entries with nil ended_at' do
        running_entry = create(:time_entry, :running, user: user, project: project)
        stopped_entry = create(:time_entry, :stopped, user: user, project: project)

        expect(TimeEntry.running).to include(running_entry)
        expect(TimeEntry.running).not_to include(stopped_entry)
      end
    end

    describe '.today' do
      it 'returns time entries started today' do
        travel_to Time.current do
          today_entry = create(:time_entry,
                              user: user,
                              project: project,
                              started_at: Time.current.beginning_of_day + 9.hours)
          yesterday_entry = create(:time_entry,
                                  user: user,
                                  project: project,
                                  started_at: 1.day.ago)

          expect(TimeEntry.today).to include(today_entry)
          expect(TimeEntry.today).not_to include(yesterday_entry)
        end
      end
    end

    describe '.this_week' do
      it 'returns time entries started this week' do
        travel_to Time.current do
          this_week_entry = create(:time_entry,
                                  user: user,
                                  project: project,
                                  started_at: Date.current.beginning_of_week + 1.day)
          last_week_entry = create(:time_entry,
                                  user: user,
                                  project: project,
                                  started_at: 1.week.ago)

          expect(TimeEntry.this_week).to include(this_week_entry)
          expect(TimeEntry.this_week).not_to include(last_week_entry)
        end
      end
    end

    describe '.recent' do
      it 'returns time entries ordered by started_at descending' do
        older_entry = create(:time_entry,
                            user: user,
                            project: project,
                            started_at: 2.days.ago)
        newer_entry = create(:time_entry,
                            user: user,
                            project: project,
                            started_at: 1.day.ago)

        recent_entries = TimeEntry.where(id: [older_entry.id, newer_entry.id]).recent
        expect(recent_entries.first).to eq(newer_entry)
        expect(recent_entries.last).to eq(older_entry)
      end
    end

    describe '.billable' do
      it 'returns only billable time entries' do
        billable_entry = create(:time_entry, :billable, user: user, project: project)
        non_billable_entry = create(:time_entry, :non_billable, user: user, project: project)

        expect(TimeEntry.billable).to include(billable_entry)
        expect(TimeEntry.billable).not_to include(non_billable_entry)
      end
    end

    describe '.unbilled' do
      it 'returns billable entries that are not billed' do
        unbilled_entry = create(:time_entry,
                               user: user,
                               project: project,
                               billable: true,
                               billed: false)
        billed_entry = create(:time_entry,
                             user: user,
                             project: project,
                             billable: true,
                             billed: true)
        non_billable_entry = create(:time_entry,
                                   user: user,
                                   project: project,
                                   billable: false,
                                   billed: false)

        unbilled = TimeEntry.unbilled
        expect(unbilled).to include(unbilled_entry)
        expect(unbilled).not_to include(billed_entry, non_billable_entry)
      end
    end
  end

  describe 'instance methods' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    describe '#stop!' do
      it 'sets ended_at to current time' do
        time_entry = create(:time_entry, :running, user: user, project: project)

        travel_to Time.current do
          time_entry.stop!
          expect(time_entry.ended_at).to be_within(1.second).of(Time.current)
        end
      end

      it 'saves the record' do
        time_entry = create(:time_entry, :running, user: user, project: project)

        expect {
          time_entry.stop!
        }.to change { time_entry.reload.ended_at }.from(nil)
      end

      it 'calculates duration after stopping' do
        time_entry = create(:time_entry, :running,
                           user: user,
                           project: project,
                           started_at: 1.hour.ago)

        time_entry.stop!

        expect(time_entry.duration).to be_within(5).of(3600) # approximately 1 hour
      end
    end

    describe '#running?' do
      it 'returns true when ended_at is nil' do
        time_entry = create(:time_entry, :running, user: user, project: project)
        expect(time_entry.running?).to be true
      end

      it 'returns false when ended_at is present' do
        time_entry = create(:time_entry, :stopped, user: user, project: project)
        expect(time_entry.running?).to be false
      end
    end

    describe '#formatted_duration' do
      it 'returns "Running..." for running time entries' do
        time_entry = create(:time_entry, :running, user: user, project: project)
        expect(time_entry.formatted_duration).to eq("Running...")
      end

      it 'formats duration as HH:MM:SS' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 2.hours.ago,
                           ended_at: 1.hour.ago) # 1 hour = 3600 seconds

        expect(time_entry.formatted_duration).to eq("01:00:00")
      end

      it 'formats duration with minutes and seconds' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: Time.current - 3665.seconds,
                           ended_at: Time.current) # 1h 1m 5s

        expect(time_entry.formatted_duration).to eq("01:01:05")
      end

      it 'handles durations less than an hour' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 15.minutes.ago,
                           ended_at: Time.current) # 15 minutes

        expect(time_entry.formatted_duration).to match(/00:1\d:/)
      end

      it 'handles multi-hour durations' do
        time_entry = create(:time_entry,
                           user: user,
                           project: project,
                           started_at: 5.hours.ago,
                           ended_at: Time.current) # 5 hours

        expect(time_entry.formatted_duration).to match(/0[45]:/)
      end
    end
  end

  describe 'business logic' do
    let(:user) { create(:user) }
    let(:project) { create(:project) }

    it 'can be created as running' do
      time_entry = create(:time_entry, :running, user: user, project: project)

      expect(time_entry).to be_persisted
      expect(time_entry.running?).to be true
      expect(time_entry.ended_at).to be_nil
    end

    it 'can be created as stopped' do
      time_entry = create(:time_entry, :stopped, user: user, project: project)

      expect(time_entry).to be_persisted
      expect(time_entry.running?).to be false
      expect(time_entry.ended_at).to be_present
    end

    it 'transitions from running to stopped' do
      time_entry = create(:time_entry, :running, user: user, project: project)

      expect {
        time_entry.stop!
      }.to change { time_entry.running? }.from(true).to(false)
    end

    it 'can be marked as billed' do
      time_entry = create(:time_entry,
                         user: user,
                         project: project,
                         billable: true,
                         billed: false)

      time_entry.update(billed: true)

      expect(time_entry.billed).to be true
      expect(TimeEntry.unbilled).not_to include(time_entry)
    end
  end
end