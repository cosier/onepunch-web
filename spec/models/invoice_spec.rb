require 'rails_helper'

RSpec.describe Invoice, type: :model do
  describe 'associations' do
    it { should belong_to(:organization) }
    it { should belong_to(:client) }
    it { should belong_to(:project).optional }
    it { should have_many(:line_items).class_name('InvoiceLineItem').dependent(:destroy) }
  end

  describe 'validations' do
    subject { create(:invoice) }

    it { should validate_presence_of(:number) }
    it { should validate_presence_of(:issued_at) }
    it { should validate_presence_of(:due_at) }

    describe 'number uniqueness' do
      it 'validates uniqueness scoped to organization' do
        invoice1 = create(:invoice, number: 'INV-0001')
        invoice2 = build(:invoice, organization: invoice1.organization, number: 'INV-0001')

        expect(invoice2).not_to be_valid
        expect(invoice2.errors[:number]).to include('has already been taken')
      end

      it 'allows same number in different organizations' do
        org1 = create(:organization)
        org2 = create(:organization)

        invoice1 = create(:invoice, organization: org1, number: 'INV-0001')
        invoice2 = build(:invoice, organization: org2, number: 'INV-0001')

        expect(invoice2).to be_valid
      end
    end
  end

  describe 'enums' do
    it { should define_enum_for(:status).with_values(draft: 0, sent: 1, paid: 2, overdue: 3, cancelled: 4) }

    it 'can be created as draft' do
      invoice = create(:invoice, :draft)
      expect(invoice.draft?).to be true
    end

    it 'can transition to sent' do
      invoice = create(:invoice, :draft)
      invoice.update(status: :sent)
      expect(invoice.sent?).to be true
    end

    it 'can be marked as paid' do
      invoice = create(:invoice, :sent)
      invoice.update(status: :paid)
      expect(invoice.paid?).to be true
    end
  end

  describe 'scopes' do
    let(:organization) { create(:organization) }

    describe '.unpaid' do
      it 'returns invoices that are sent or overdue' do
        sent_invoice = create(:invoice, :sent, organization: organization)
        overdue_invoice = create(:invoice, :overdue, organization: organization)
        paid_invoice = create(:invoice, :paid, organization: organization)
        draft_invoice = create(:invoice, :draft, organization: organization)

        unpaid = Invoice.unpaid
        expect(unpaid).to include(sent_invoice, overdue_invoice)
        expect(unpaid).not_to include(paid_invoice, draft_invoice)
      end
    end
  end

  describe 'callbacks' do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }

    describe 'generate_number' do
      it 'generates invoice number on create' do
        invoice = create(:invoice, organization: organization, client: client, number: nil)
        expect(invoice.number).to match(/INV-\d{4}/)
      end

      it 'generates sequential invoice numbers' do
        invoice1 = create(:invoice, organization: organization, client: client, number: nil)
        invoice2 = create(:invoice, organization: organization, client: client, number: nil)

        expect(invoice2.number).to be > invoice1.number
      end

      it 'does not override existing number' do
        invoice = create(:invoice, organization: organization, client: client, number: 'CUSTOM-001')
        expect(invoice.number).to eq('CUSTOM-001')
      end
    end

    describe 'calculate_totals' do
      it 'calculates subtotal from line items' do
        invoice = create(:invoice, organization: organization, client: client)
        invoice.line_items.create!(description: 'Item 1', quantity: 2, unit_price: 50, amount: 100)
        invoice.line_items.create!(description: 'Item 2', quantity: 1, unit_price: 75, amount: 75)

        invoice.save!

        expect(invoice.subtotal).to eq(175.0)
      end

      it 'calculates tax amount based on tax_rate' do
        invoice = create(:invoice, organization: organization, client: client, tax_rate: 10)
        invoice.line_items.create!(description: 'Item', quantity: 1, unit_price: 100, amount: 100)

        invoice.save!

        expect(invoice.tax_amount).to eq(10.0)
      end

      it 'calculates total as subtotal plus tax' do
        invoice = create(:invoice, organization: organization, client: client, tax_rate: 15)
        invoice.line_items.create!(description: 'Item', quantity: 1, unit_price: 100, amount: 100)

        invoice.save!

        expect(invoice.total).to eq(115.0)
      end

      it 'handles zero tax rate' do
        invoice = create(:invoice, organization: organization, client: client, tax_rate: 0)
        invoice.line_items.create!(description: 'Item', quantity: 1, unit_price: 100, amount: 100)

        invoice.save!

        expect(invoice.tax_amount).to eq(0.0)
        expect(invoice.total).to eq(100.0)
      end
    end
  end

  describe 'instance methods' do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }

    describe '#mark_as_paid!' do
      it 'updates status to paid' do
        invoice = create(:invoice, :sent, organization: organization, client: client)

        invoice.mark_as_paid!

        expect(invoice.status).to eq('paid')
        expect(invoice.paid?).to be true
      end

      it 'sets paid_at timestamp' do
        invoice = create(:invoice, :sent, organization: organization, client: client)

        invoice.mark_as_paid!

        expect(invoice.paid_at).to be_present
        expect(invoice.paid_at).to eq(Date.current)
      end
    end

    describe '#overdue?' do
      it 'returns true when due_at is past and not paid' do
        invoice = create(:invoice, :sent,
                        organization: organization,
                        client: client,
                        due_at: 10.days.ago)

        expect(invoice.overdue?).to be true
      end

      it 'returns false when due_at is future' do
        invoice = create(:invoice, :sent,
                        organization: organization,
                        client: client,
                        due_at: 10.days.from_now)

        expect(invoice.overdue?).to be false
      end

      it 'returns false when invoice is paid' do
        invoice = create(:invoice, :paid,
                        organization: organization,
                        client: client,
                        due_at: 10.days.ago)

        expect(invoice.overdue?).to be false
      end
    end
  end

  describe 'business logic' do
    let(:organization) { create(:organization) }
    let(:client) { create(:client, organization: organization) }

    it 'can create invoice with line items' do
      invoice = create(:invoice, organization: organization, client: client)
      invoice.line_items.create!(description: 'Service', quantity: 10, unit_price: 50, amount: 500)
      invoice.save!

      expect(invoice.line_items.count).to eq(1)
      expect(invoice.reload.subtotal).to eq(500.0)
    end

    it 'supports invoice lifecycle draft → sent → paid' do
      invoice = create(:invoice, :draft, organization: organization, client: client)

      expect(invoice.draft?).to be true

      invoice.update(status: :sent)
      expect(invoice.sent?).to be true

      invoice.mark_as_paid!
      expect(invoice.paid?).to be true
    end

    it 'can be cancelled' do
      invoice = create(:invoice, :sent, organization: organization, client: client)

      invoice.update(status: :cancelled)

      expect(invoice.cancelled?).to be true
    end
  end
end