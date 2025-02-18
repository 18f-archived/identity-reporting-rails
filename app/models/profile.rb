class Profile < DataWarehouseApplicationRecord
  self.table_name = 'idp.profiles'

  belongs_to :user

  def self.active
    where(active: true)
  end

  def self.verified
    where.not(verified_at: nil)
  end

  def self.fraud_rejection
    where.not(fraud_rejection_at: nil)
  end

  def self.fraud_review_pending
    where.not(fraud_review_pending_at: nil)
  end

  # Instance methods
  def fraud_review_pending?
    fraud_review_pending_at.present?
  end

  def fraud_rejection?
    fraud_rejection_at.present?
  end
end
