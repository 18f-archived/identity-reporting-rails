FactoryBot.define do
  factory :production do
    cloudwatch_timestamp { Time.zone.now }
    message { { text: Faker::Lorem.sentence }.to_json }
  end
end
