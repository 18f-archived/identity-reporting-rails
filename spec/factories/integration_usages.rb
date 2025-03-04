FactoryBot.define do
  factory :integration_usage, class: 'Agreements::IntegrationUsage' do
    iaa_order
    integration
  end
end
