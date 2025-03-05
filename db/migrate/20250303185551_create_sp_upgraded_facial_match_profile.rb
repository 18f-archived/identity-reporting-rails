class CreateSpUpgradedFacialMatchProfile < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.sp_upgraded_facial_match_profiles', if_not_exists: true do |t|
      t.datetime 'upgraded_at'
      t.bigint 'user_id'
      t.string 'idv_level'
      t.string 'issuer'
      t.timestamps
    end
  end
end
