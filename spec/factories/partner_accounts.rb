FactoryBot.define do
  factory :partner_account, class: 'Agreements::PartnerAccount' do
    name { Faker::Name.name }
    description { Faker::Lorem.sentence }
    requesting_agency { Faker::Name.name }
    agency
    partner_account_status
  end
end
