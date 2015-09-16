require 'lib/saml_service_client'

RSpec.describe DiscoveryService::SAMLServiceClient do
  context '#retrieve_entity_data' do
    let(:url) { 'http://saml-service.example.com:443/entities' }

    before do
      stub_request(:get, url).to_return(response)
    end

    subject { DiscoveryService::SAMLServiceClient.retrieve_entity_data(url) }

    context 'with a SAML Service response' do
      context 'that is valid' do
        let(:response_body) do
          {
            entities: [
              {
                entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
                sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
                name: 'AAF Virtual Home',
                tags: %w(discovery idp aaf vho)
              },
              {
                entity_id: 'https://vho.test.aaf.edu.au/shibboleth',
                name: 'AAF Virtual Home',
                tags: %w(aaf sp)
              }
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
          DiscoveryService::SAMLServiceClient.retrieve_entity_data(url)
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
