require 'rails_helper'

RSpec.describe Agency do
  describe 'Associations' do
    it { is_expected.to have_many(:service_providers).inverse_of(:agency) }
    it { is_expected.to have_many(:partner_accounts).class_name('Agreements::PartnerAccount') }
  end
end
