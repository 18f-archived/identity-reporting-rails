require 'rails_helper'

RSpec.describe Agreements::IaaOrder, type: :model do
  describe 'validations and associations' do
    subject { create(:iaa_order) }

    it { is_expected.to belong_to(:iaa_gtc) }

    it { is_expected.to have_one(:partner_account).through(:iaa_gtc) }
    it { is_expected.to have_many(:integration_usages).dependent(:restrict_with_exception) }
    it { is_expected.to have_many(:integrations).through(:integration_usages) }
  end
end
