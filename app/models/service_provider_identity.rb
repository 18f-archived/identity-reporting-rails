# frozen_string_literal: true

# Joins Users to ServiceProviders
class ServiceProviderIdentity < DataWarehouseApplicationRecord
  self.table_name = 'idp.identities'

  include NonNullUuid

  belongs_to :user
  validates :service_provider, presence: true

  # rubocop:disable Rails/InverseOf
  belongs_to :deleted_user, foreign_key: 'user_id', primary_key: 'user_id'

  belongs_to :service_provider_record,
             class_name: 'ServiceProvider',
             foreign_key: 'service_provider',
             primary_key: 'issuer'
  # rubocop:enable Rails/InverseOf

  has_one :agency, through: :service_provider_record

  def friendly_name
    sp_metadata[:friendly_name]
  end

  def service_provider_id
    service_provider_record&.id
  end
end
