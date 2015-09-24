require 'discovery_service/metadata_updater'

RSpec.describe DiscoveryService::MetadataUpdater do
  context '#update' do
    let(:logger) { spy }
    let(:url) { 'http://saml-service.example.com/entities' }
    let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
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

    def run
      DiscoveryService::MetadataUpdater.new.update
    end

    context 'with successful metadata retrieval' do
      include_context 'build_entity_data'

      let(:first_entity) { build_entity_data(%w(discovery idp aaf vho)) }
      let(:second_entity) { build_entity_data(%w(discovery idp edugain vho)) }
      let(:response_body) { { entities: [first_entity, second_entity] } }
      let(:response) { { status: 200, body: JSON.generate(response_body) } }

      it 'collects entities filtered by group' do
        run
        expect(redis.get('entity_data'))
          .to eq({ aaf: [first_entity], edugain: [second_entity] }.to_json)
      end
    end

    context 'with unsuccessful metadata retrieval' do
      let(:response) { { status: 400, body: JSON.generate([]) } }

      it 'propagates the exception' do
        expect { run }.to raise_error(Net::HTTPServerException)
        expect(logger).to have_received(:error)
      end
    end
  end
end
