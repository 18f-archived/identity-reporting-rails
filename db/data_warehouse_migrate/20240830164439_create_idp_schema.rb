class CreateIdpSchema < ActiveRecord::Migration[7.1]
  def change
    reversible do |dir|
      dir.up { execute 'CREATE SCHEMA IF NOT EXISTS idp' }
      dir.down { execute 'DROP SCHEMA IF EXISTS idp' }
    end
  end
end
