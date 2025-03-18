# rubocop:disable Rails/CreateTableWithTimestamps
class CreateSpReturnLogs < ActiveRecord::Migration[7.2]
  def change
    create_table 'idp.sp_return_logs', if_not_exists: true do |t|
      t.datetime 'requested_at'
      t.string 'request_id', null: false, index: true
      t.integer 'ial'
      t.string 'issuer', null: false
      t.integer 'user_id'
      t.datetime 'returned_at'
      t.boolean 'billable', default: false, null: false
      t.bigint 'profile_id'
      t.datetime 'profile_verified_at'
      t.string 'profile_requested_issuer'
    end
  end
end
# rubocop:enable Rails/CreateTableWithTimestamps
