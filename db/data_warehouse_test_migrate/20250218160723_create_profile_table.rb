class CreateProfileTable < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.profiles', if_not_exists: true do |t|
      t.integer :user_id, null: false, index: true
      t.boolean :active, default: false
      t.datetime :verified_at
      t.datetime :activated_at
      t.datetime :created_at, null: false
      t.datetime :updated_at, null: false
      t.integer :deactivation_reason
      t.jsonb :proofing_components, default: {}
      t.string :initiating_service_provider_issuer
      t.datetime :fraud_review_pending_at
      t.datetime :fraud_rejection_at
      t.datetime :gpo_verification_pending_at
      t.integer :fraud_pending_reason
      t.datetime :gpo_verification_expired_at
      t.integer :idv_level
      t.datetime :in_person_verification_pending_at

      t.timestamp :timestamp
    end
  end
end
