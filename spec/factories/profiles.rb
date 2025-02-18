FactoryBot.define do
  factory :profile do
    association :user, factory: %i[user fully_registered]

    transient do
      pii { false }
    end

    idv_level { :legacy_unsupervised }

    trait :active do
      active { true }
      activated_at { Time.zone.now }
      verified_at { Time.zone.now }
    end

    trait :deactivated do
      active { false }
      activated_at { Time.zone.now }
    end

    # TODO: just use active
    trait :verified do
      verified_at { Time.zone.now }
      activated_at { Time.zone.now }
    end

    trait :fraud_pending_reason do
      fraud_pending_reason { 'threatmetrix_review' }
      proofing_components { { threatmetrix_review_status: 'review' } }
    end

    trait :fraud_review_pending do
      fraud_pending_reason { 'threatmetrix_review' }
      fraud_review_pending_at { 15.days.ago }
      proofing_components { { threatmetrix_review_status: 'review' } }
    end

    trait :verify_by_mail_pending do
      gpo_verification_pending_at { 1.day.ago }
    end

    # flagged by TM for review, eventually rejected by us
    trait :fraud_rejection do
      fraud_pending_reason { 'threatmetrix_review' }
      fraud_rejection_at { 15.days.ago }
    end

    trait :verification_cancelled do
      deactivation_reason { :verification_cancelled }
    end
  end
end
