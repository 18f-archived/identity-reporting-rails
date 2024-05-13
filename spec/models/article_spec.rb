require 'rails_helper'

RSpec.describe Article, type: :model do
  it 'has a valid factory' do
    article = FactoryBot.build(:article)
    expect(article).to be_valid
  end
end
