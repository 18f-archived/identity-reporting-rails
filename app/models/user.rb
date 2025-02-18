class User < DataWarehouseApplicationRecord
  self.table_name = 'idp.users'
  self.primary_key = 'id'

  has_many :profiles, dependent: :destroy
end
