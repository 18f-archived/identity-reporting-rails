# frozen_string_literal: true

class Agreements::IntegrationStatus < DataWarehouseApplicationRecord
  self.table_name = 'idp.integration_statuses'
  self.primary_key = 'id'

  has_many :integrations, dependent: :restrict_with_exception

  validates :name, presence: true, uniqueness: true
  validates :order, presence: true,
                    uniqueness: true,
                    numericality: { only_integer: true }
end
