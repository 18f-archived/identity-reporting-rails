class User < DataWarehouseApplicationRecord
  self.table_name = 'idp.users'
  self.primary_key = 'id'
end
