class Agreements::PartnerAccountStatus < DataWarehouseApplicationRecord
  self.table_name = 'idp.partner_account_statuses'
  self.primary_key = 'id'
  has_many :partner_accounts, dependent: :restrict_with_exception,
                              class_name: 'Agreements::PartnerAccount'
end
