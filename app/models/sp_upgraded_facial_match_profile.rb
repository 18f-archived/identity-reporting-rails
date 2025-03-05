# frozen_string_literal: true

class SpUpgradedFacialMatchProfile < DataWarehouseApplicationRecord
  self.table_name = 'idp.sp_upgraded_biometric_profiles'

  belongs_to :user
end
