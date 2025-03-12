# rubocop:disable Metrics/BlockLength
class CreateServiceProvideTable < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.service_providers', if_not_exists: true do |t|
      t.string :issuer, null: false
      t.string :friendly_name
      t.text :description
      t.text :metadata_url
      t.text :acs_url
      t.text :assertion_consumer_logout_service_url
      t.text :logo
      t.string :signature
      t.string :block_encryption, default: 'aes256-cbc', null: false
      t.text :sp_initiated_login_url
      t.text :return_to_sp_url
      t.json :attribute_bundle
      t.boolean :active, default: false, null: false
      t.boolean :approved, default: false, null: false
      t.boolean :native, default: false, null: false
      t.string :redirect_uris, default: [], array: true
      t.integer :agency_id
      t.text :failure_to_proof_url
      t.integer :ial
      t.boolean :piv_cac, default: false, null: false
      t.boolean :piv_cac_scoped_by_email, default: false, null: false
      t.boolean :pkce, default: false, null: false
      t.string :push_notification_url
      t.jsonb :help_text, default: { 'sign_in' => {}, 'sign_up' => {}, 'forgot_password' => {} }
      t.boolean :allow_prompt_login, default: false, null: false
      t.boolean :signed_response_message_requested, default: false, null: false
      t.string :remote_logo_key
      t.date :launch_date
      t.string :iaa
      t.date :iaa_start_date
      t.date :iaa_end_date
      t.string :app_id
      t.integer :default_aal
      t.string :certs
      t.boolean :email_nameid_format_allowed, default: false, null: false
      t.boolean :use_legacy_name_id_behavior, default: false, null: false
      t.boolean :irs_attempts_api_enabled, default: false, null: false
      t.boolean :in_person_proofing_enabled, default: false, null: false
      t.string :post_idv_follow_up_url
      t.timestamps
    end
  end
end
# rubocop:enable Metrics/BlockLength
