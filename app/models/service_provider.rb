class ServiceProvider < DataWarehouseApplicationRecord
  self.table_name = 'idp.service_providers'
  self.primary_key = 'id'
  belongs_to :agency
  # rubocop:disable Rails/HasManyOrHasOneDependent
  # In order to preserve unique user UUIDs, we do not want to destroy Identity records
  # when we destroy a ServiceProvider
  has_many :identities, inverse_of: :service_provider_record,
                        foreign_key: 'service_provider',
                        primary_key: 'issuer',
                        class_name: 'ServiceProviderIdentity'
  # rubocop:enable Rails/HasManyOrHasOneDependent

  has_one :integration,
          inverse_of: :service_provider,
          foreign_key: 'issuer',
          primary_key: 'issuer',
          class_name: 'Agreements::Integration',
          dependent: nil
end
