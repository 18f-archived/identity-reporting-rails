FactoryBot.define do
  factory :unextracted_production do
    cloudwatch_timestamp { Time.zone.now }
    message { { text: Faker::Lorem.sentence }.to_json }
  end
end
