require 'rails_helper'

RSpec.describe ServiceProvider do
  let(:service_provider) { create(:service_provider, issuer: 'http://localhost:3000') }

  describe 'associations' do
    subject { service_provider }

    it { is_expected.to belong_to(:agency) }
  end

  describe '#issuer' do
    it 'returns the constructor value' do
      expect(service_provider.issuer).to eq 'http://localhost:3000'
    end
  end
end
