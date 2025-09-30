FactoryBot.define do
  factory :invoice_line_item do
    association :invoice
    description { "Consulting services" }
    quantity { 10.0 }
    rate { 100.0 }
    amount { 1000.0 }
  end
end