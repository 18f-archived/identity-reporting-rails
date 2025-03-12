class Agency < DataWarehouseApplicationRecord
  self.table_name = 'idp.agencies'
  self.primary_key = 'id'

  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :service_providers, inverse_of: :agency
  has_many :partner_accounts, class_name: 'Agreements::PartnerAccount'
  # rubocop:enable Rails/HasManyOrHasOneDependent
end
