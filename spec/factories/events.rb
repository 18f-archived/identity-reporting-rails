FactoryBot.define do
  factory :event do
    timestamp { Time.now }
    message { { text: Faker::Lorem.sentence }.to_json }
  end
end
