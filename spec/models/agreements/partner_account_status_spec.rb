require 'rails_helper'

RSpec.describe Agreements::PartnerAccountStatus, type: :model do
  describe 'validations and associations' do
    subject { build(:partner_account_status) }

    it { is_expected.to have_many(:partner_accounts) }
  end

  describe '#partner_name' do
    it 'returns the partner_name if set' do
      status = build(:partner_account_status, name: 'foo', partner_name: 'bar')
      expect(status.partner_name).to eq('bar')
    end
  end
end
