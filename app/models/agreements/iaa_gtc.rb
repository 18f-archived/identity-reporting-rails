class Agreements::IaaGtc < DataWarehouseApplicationRecord
  self.table_name = 'idp.iaa_gtcs'
  self.primary_key = 'id'

  belongs_to :partner_account

  has_many :iaa_orders, dependent: :restrict_with_exception
  has_many :integrations, through: :iaa_orders
  has_many :service_providers, through: :integrations
end
