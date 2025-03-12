class Agreements::IntegrationUsage < DataWarehouseApplicationRecord
  self.table_name = 'idp.integration_usages'
  self.primary_key = 'id'

  belongs_to :iaa_order, -> { includes(iaa_gtc: :partner_account) },
             inverse_of: :integration_usages
  belongs_to :integration, -> { includes(:partner_account) },
             inverse_of: :integration_usages

  has_one :partner_account, through: :integration
end
