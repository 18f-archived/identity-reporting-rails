FactoryBot.define do
  factory :partner_account_status, class: 'Agreements::PartnerAccountStatus' do
    name  { Faker::Name.name }
    order { Faker::Number.number(digits: 2) }
  end
end
