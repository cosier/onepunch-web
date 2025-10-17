require 'rails_helper'

RSpec.describe InvoiceLineItem, type: :model do
  describe 'associations' do
    it { should belong_to(:invoice) }
  end

  describe 'validations' do
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:quantity) }
    it { should validate_presence_of(:unit_price) }

    it { should validate_numericality_of(:quantity).is_greater_than(0) }
    it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }

    it 'allows zero unit_price' do
      invoice = create(:invoice)
      line_item = build(:invoice_line_item, invoice: invoice, unit_price: 0, quantity: 1)

      expect(line_item).to be_valid
    end

    it 'does not allow negative quantity' do
      invoice = create(:invoice)
      line_item = build(:invoice_line_item, invoice: invoice, quantity: -1)

      expect(line_item).not_to be_valid
      expect(line_item.errors[:quantity]).to be_present
    end

    it 'does not allow negative unit_price' do
      invoice = create(:invoice)
      line_item = build(:invoice_line_item, invoice: invoice, unit_price: -10)

      expect(line_item).not_to be_valid
      expect(line_item.errors[:unit_price]).to be_present
    end
  end

  describe 'callbacks' do
    let(:invoice) { create(:invoice) }

    describe 'calculate_amount' do
      it 'calculates amount from quantity and unit_price' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 5, unit_price: 100)

        expect(line_item.amount).to eq(500.0)
      end

      it 'updates amount when quantity changes' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 2, unit_price: 50)
        expect(line_item.amount).to eq(100.0)

        line_item.update(quantity: 4)
        expect(line_item.amount).to eq(200.0)
      end

      it 'updates amount when unit_price changes' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 3, unit_price: 25)
        expect(line_item.amount).to eq(75.0)

        line_item.update(unit_price: 50)
        expect(line_item.amount).to eq(150.0)
      end

      it 'handles decimal quantities' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 2.5, unit_price: 100)

        expect(line_item.amount).to eq(250.0)
      end

      it 'handles decimal unit_prices' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 3, unit_price: 33.33)

        expect(line_item.amount).to eq(99.99)
      end

      it 'calculates zero amount for zero unit_price' do
        line_item = create(:invoice_line_item, invoice: invoice, quantity: 10, unit_price: 0)

        expect(line_item.amount).to eq(0.0)
      end
    end
  end

  describe 'business logic' do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }
    let(:invoice) { create(:invoice, organization: organization, client: client) }

    it 'belongs to an invoice' do
      line_item = create(:invoice_line_item, invoice: invoice)

      expect(line_item.invoice).to eq(invoice)
    end

    it 'requires all fields to be valid' do
      line_item = build(:invoice_line_item,
                       invoice: invoice,
                       description: 'Consulting',
                       quantity: 8,
                       unit_price: 125)

      expect(line_item).to be_valid
    end

    it 'can have long descriptions' do
      long_description = 'a' * 500
      line_item = create(:invoice_line_item, invoice: invoice, description: long_description)

      expect(line_item.description).to eq(long_description)
    end
  end
end