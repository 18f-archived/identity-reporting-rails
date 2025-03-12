class Agreements::PartnerAccount < DataWarehouseApplicationRecord
  self.table_name = 'idp.partner_accounts'
  self.primary_key = 'id'
  belongs_to :agency
  belongs_to :partner_account_status, class_name: 'Agreements::PartnerAccountStatus'

  has_many :iaa_gtcs, dependent: :restrict_with_exception
  has_many :iaa_orders, through: :iaa_gtcs
  has_many :integrations, dependent: :restrict_with_exception
end
