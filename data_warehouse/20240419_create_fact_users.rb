# frozen_string_literal: true

class CreateFactUsers < ActiveRecord::Migration[7.1]
    def change
      # Uncomment for Postgres v12 or earlier to enable gen_random_uuid() support
      # enable_extension 'pgcrypto'

      create_table :fact_users, id: :uuid do |t|
        t.string :name
        t.string :email
  
        t.timestamps
      end
    end
  end
  