require 'lib/discovery_service/saml_service_client'

RSpec.describe DiscoveryService::SAMLServiceClient do
  context '#retrieve_entity_data' do
    include_context 'build_entity_data'
    let(:logger) { spy }

    let(:klass) do
      Class.new do
        attr_accessor :logger
        include DiscoveryService::SAMLServiceClient
        def initialize
          @logger = Logger.new($stderr)
        end
      end
    end

    let(:url) { 'http://saml-service.example.com/entities' }

    before do
      allow(Logger).to receive(:new).and_return(logger)
      stub_request(:get, url).to_return(response)
    end

    subject { klass.new.retrieve_entity_data(url) }

    context 'with a SAML Service response' do
      context 'that is valid' do
        let(:response_body) do
          {
            entities: [
              build_entity_data(%w(discovery idp aaf vho)),
              build_entity_data(%w(aaf sp))
            ]
          }
        end

        let(:response) do
          { status: 200, body: JSON.generate(response_body) }
        end

        it 'unmarshalls the payload to JSON as expected' do
          expect(subject).to eq(response_body)
        end
      end

      context 'that is not valid' do
        def run
          klass.new.retrieve_entity_data(url)
        end

        let(:response) do
          { status: 400, body: JSON.generate([]) }
        end

        it 'propagates the exception' do
          expect { run }.to raise_error(Net::HTTPServerException)
        end
      end
    end
  end
end
