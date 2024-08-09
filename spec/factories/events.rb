FactoryBot.define do
  factory :event do
    cloudwatch_timestamp { Time.zone.now }
    name { Faker::Book.title }
  end
end
