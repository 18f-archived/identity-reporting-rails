class CreateUserTable < ActiveRecord::Migration[7.2]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS idp' }
      dir.down { execute 'DROP SCHEMA IF EXISTS idp' }
    end

    create_table 'idp.users', if_not_exists: true do |t|
      t.datetime :reset_password_sent_at
      t.datetime :confirmed_at
      t.integer  :second_factor_attempts_count, default: 0, null: false
      t.string   :uuid, null: false
      t.datetime :second_factor_locked_at
      t.datetime :phone_confirmed_at
      t.datetime :direct_otp_sent_at
      t.string   :unique_session_id
      t.integer  :otp_delivery_preference, default: 0, null: false
      t.datetime :remember_device_revoked_at
      t.string   :email_language
      t.datetime :accepted_terms_at
      t.datetime :suspended_at
      t.datetime :reinstated_at
      t.datetime :password_compromised_checked_at
      t.datetime :piv_cac_recommended_dismissed_at
      t.datetime :second_mfa_reminder_dismissed_at
      t.datetime :sign_in_new_device_at
      t.datetime :webauthn_platform_recommended_dismissed_at

      t.timestamp :timestamp
    end
  end
end
