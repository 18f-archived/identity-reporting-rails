class Event < DataWarehouseApplicationRecord
  self.table_name = 'logs.events'
  default_scope { order(id: :asc) }
end
