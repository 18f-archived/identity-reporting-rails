class Agreements::Integration < DataWarehouseApplicationRecord
  self.table_name = 'idp.integrations'
  self.primary_key = 'id'

  belongs_to :partner_account
  belongs_to :service_provider, foreign_key: :issuer, primary_key: :issuer, inverse_of: :integration

  has_many :integration_usages, dependent: :restrict_with_exception
  has_many :iaa_orders, through: :integration_usages
end
