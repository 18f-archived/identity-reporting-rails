# rubocop:disable Rails/ApplicationRecord
class DataWarehouseApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :data_warehouse, reading: :data_warehouse }
end
# rubocop:enable Rails/ApplicationRecord
