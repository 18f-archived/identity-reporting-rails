FactoryBot.define do
  Faker::Config.locale = :en

  factory :user do
    uuid { SecureRandom.uuid }
    transient do
      with { {} }
      sequence(:email) { |n| "user#{n}@example.com" }
      confirmed_at { Time.zone.now }
      confirmation_token { nil }
      confirmation_sent_at { 5.minutes.ago }
      registered_at { Time.zone.now }
    end

    trait :fully_registered do
    end

    trait :unconfirmed do
      confirmed_at { nil }
      password { nil }
    end

    trait :proofed do
      fully_registered
      confirmed_at { Time.zone.now.round }

      after :build do |user|
        create(
          :profile,
          :active,
          user: user,
        )
      end
    end

    trait :fraud_review_pending do
      fully_registered

      after :build do |user|
        create(
          :profile,
          :fraud_review_pending,
          :verified,
          user: user,
        )
      end
    end

    trait :fraud_rejection do
      fully_registered

      after :build do |user|
        create(
          :profile,
          :fraud_rejection,
          :verified,
          user: user,
        )
      end
    end

    trait :suspended do
      suspended_at { Time.zone.now }
      reinstated_at { nil }
    end

    trait :reinstated do
      suspended_at { Time.zone.now }
      reinstated_at { Time.zone.now + 1.hour }
    end
  end
end
