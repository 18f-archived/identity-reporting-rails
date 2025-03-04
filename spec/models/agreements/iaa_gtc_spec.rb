require 'rails_helper'

RSpec.describe Agreements::IaaGtc, type: :model do
  describe 'validations and associations' do
    subject { create(:iaa_gtc) }

    it { is_expected.to belong_to(:partner_account) }

    it { is_expected.to have_many(:iaa_orders).dependent(:restrict_with_exception) }
  end
end
