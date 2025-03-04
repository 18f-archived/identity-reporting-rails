class Agreements::IaaOrder < DataWarehouseApplicationRecord
  self.table_name = 'idp.iaa_orders'
  self.primary_key = 'id'

  belongs_to :iaa_gtc
  has_one :partner_account, through: :iaa_gtc

  has_one :partner_account, through: :iaa_gtc
  has_many :integration_usages, dependent: :restrict_with_exception
  has_many :integrations, through: :integration_usages
end
