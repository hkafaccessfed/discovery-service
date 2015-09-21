require 'discovery_service/metadata_updater'

RSpec.describe DiscoveryService::MetadataUpdater do
  context '#update' do
    let(:logger) { spy }
    let(:url) { 'http://saml-service.example.com/entities' }
    let(:config) do
      { saml_service: { uri: url },
        collections: { aaf: [%w(discovery aaf)],
                       edugain: [%w(discovery edugain)] } }
    end

    before do
      allow(Logger).to receive(:new).and_return(logger)
      allow(YAML).to receive(:load_file).and_return(config)
      stub_request(:get, url).to_return(response)
    end

    subject { DiscoveryService::MetadataUpdater.new.update }

    context 'with successful metadata retrieval' do
      include_context 'build_entity_data'

      let(:first_entity) { build_entity_data(%w(discovery idp aaf vho)) }
      let(:second_entity) { build_entity_data(%w(discovery idp edugain vho)) }
      let(:response_body) { { entities: [first_entity, second_entity] } }
      let(:response) { { status: 200, body: JSON.generate(response_body) } }

      # TODO: Change this test to ensure data is persisted in redis
      it 'collects entities filtered by group' do
        expect(subject).to eq(aaf: [first_entity], edugain: [second_entity])
      end
    end

    context 'with unsuccessful metadata retrieval' do
      def run
        DiscoveryService::MetadataUpdater.new.update
      end

      let(:response) { { status: 400, body: JSON.generate([]) } }

      it 'propagates the exception' do
        expect { run }.to raise_error(Net::HTTPServerException)
        expect(logger).to have_received(:error)
      end
    end
  end
end
