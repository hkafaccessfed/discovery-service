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

      let(:matching_aaf_entity) { build_entity_data(%w(discovery idp aaf vho)) }

      let(:matching_edugain_entity) do
        build_entity_data(%w(discovery idp edugain vho))
      end
      let(:non_matching_tuakiri_entity) do
        build_entity_data(%w(discovery idp tuakiri vho))
      end

      let(:response_body) do
        { entities: [matching_aaf_entity, matching_edugain_entity,
                     non_matching_tuakiri_entity] }
      end

      let(:response) { { status: 200, body: JSON.generate(response_body) } }

      it 'stores each matching entity as a key value pair' do
        run
        expect(redis.keys)
          .to eq(['entities:aaf', 'entities:edugain'])
        expect(redis.get('entities:aaf'))
          .to eq([matching_aaf_entity].to_json)
        expect(redis.get('entities:edugain'))
          .to eq([matching_edugain_entity].to_json)
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
