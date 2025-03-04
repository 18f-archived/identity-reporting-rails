require 'rails_helper'

RSpec.describe Agreements::IntegrationUsage, type: :model do
  describe 'validations and associations' do
    subject { create(:integration_usage) }

    it { is_expected.to belong_to(:iaa_order) }
    it { is_expected.to belong_to(:integration) }

    it { is_expected.to have_one(:partner_account).through(:integration) }
  end
end
