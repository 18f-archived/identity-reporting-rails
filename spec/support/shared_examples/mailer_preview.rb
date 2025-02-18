RSpec.shared_examples 'a mailer preview' do
  let(:mailer_class) { described_class.class_name.gsub(/Preview$/, '').constantize }

  it 'has a preview method for each mailer method' do
    mailer_methods = mailer_class.instance_methods(false)
    preview_methods = described_class.instance_methods(false)
    expect(mailer_methods - preview_methods).to eql([])
  end

  described_class.instance_methods(false).each do |mailer_method|
    describe "##{mailer_method}" do
      subject(:mail) { described_class.new.public_send(mailer_method) }
      let(:body) { mail.parts.find { |part| part.content_type.start_with?('text/') }.body }

      it 'generates a preview without blowing up' do
        expect { body }.to_not raise_error
      end
    end
  end
end
