FactoryBot.define do
  factory :integration, class: 'Agreements::Integration' do
    partner_account
    service_provider
  end
end
