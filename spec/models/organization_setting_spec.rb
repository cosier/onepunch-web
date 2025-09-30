require 'rails_helper'

RSpec.describe OrganizationSetting, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
  end

  describe 'validations' do
    let(:setting) { create(:organization_setting) }
    subject { setting }

    it { should validate_presence_of(:invoice_prefix) }
    it { should validate_presence_of(:invoice_counter) }
    it { should validate_presence_of(:currency) }
    it { should validate_presence_of(:time_zone) }
    it { should validate_presence_of(:date_format) }

    describe 'invoice_counter' do
      it 'must be at least 1' do
        setting.invoice_counter = 0
        expect(setting).not_to be_valid
        expect(setting.errors[:invoice_counter]).to be_present
      end

      it 'allows values >= 1' do
        setting.invoice_counter = 1
        expect(setting).to be_valid
      end
    end

    describe 'tax_rate' do
      it 'must be between 0 and 100' do
        setting.tax_rate = -1
        expect(setting).not_to be_valid

        setting.tax_rate = 101
        expect(setting).not_to be_valid

        setting.tax_rate = 0
        expect(setting).to be_valid

        setting.tax_rate = 100
        expect(setting).to be_valid

        setting.tax_rate = 50
        expect(setting).to be_valid
      end

      it 'allows nil' do
        setting.tax_rate = nil
        expect(setting).to be_valid
      end
    end

    describe 'default_hourly_rate' do
      it 'must be >= 0' do
        setting.default_hourly_rate = -1
        expect(setting).not_to be_valid

        setting.default_hourly_rate = 0
        expect(setting).to be_valid

        setting.default_hourly_rate = 100
        expect(setting).to be_valid
      end

      it 'allows nil' do
        setting.default_hourly_rate = nil
        expect(setting).to be_valid
      end
    end
  end

  describe 'callbacks' do
    describe 'increment_invoice_counter' do
      it 'increments invoice_counter after creation' do
        # Create a setting explicitly since the callback creates it
        setting = create(:organization_setting, invoice_counter: 1)
        initial_counter = 1

        # The after_create callback should have incremented it
        expect(setting.reload.invoice_counter).to eq(initial_counter + 1)
      end
    end
  end

  describe 'instance methods' do
    let(:setting) { create(:organization_setting) }

    describe '#next_invoice_number' do
      it 'formats invoice number with prefix and zero-padded counter' do
        setting.update(invoice_prefix: 'INV', invoice_counter: 1)
        expect(setting.next_invoice_number).to eq('INV-00001')
      end

      it 'handles large counter numbers' do
        setting.update(invoice_prefix: 'INV', invoice_counter: 12345)
        expect(setting.next_invoice_number).to eq('INV-12345')
      end

      it 'pads numbers less than 5 digits' do
        setting.update(invoice_prefix: 'BILL', invoice_counter: 42)
        expect(setting.next_invoice_number).to eq('BILL-00042')
      end

      it 'works with different prefixes' do
        setting.update(invoice_prefix: 'QUOTE', invoice_counter: 999)
        expect(setting.next_invoice_number).to eq('QUOTE-00999')
      end
    end

    describe '#increment_invoice_counter' do
      it 'increments the counter by 1' do
        setting.update(invoice_counter: 10)

        expect {
          setting.increment_invoice_counter
        }.to change { setting.reload.invoice_counter }.from(10).to(11)
      end

      it 'persists the change' do
        setting.update(invoice_counter: 5)
        setting.increment_invoice_counter

        # Create new instance to verify persistence
        reloaded = OrganizationSetting.find(setting.id)
        expect(reloaded.invoice_counter).to eq(6)
      end
    end
  end

  describe 'business logic' do
    let(:setting) { create(:organization_setting) }

    it 'provides sensible defaults' do
      expect(setting.currency).to be_present
      expect(setting.time_zone).to be_present
      expect(setting.date_format).to be_present
    end

    it 'supports sequential invoice numbering' do
      setting.update(invoice_prefix: 'INV', invoice_counter: 100)

      # Simulate generating 3 invoices
      inv1 = setting.next_invoice_number
      setting.increment_invoice_counter

      inv2 = setting.next_invoice_number
      setting.increment_invoice_counter

      inv3 = setting.next_invoice_number

      expect(inv1).to eq('INV-00100')
      expect(inv2).to eq('INV-00101')
      expect(inv3).to eq('INV-00102')
    end
  end
end