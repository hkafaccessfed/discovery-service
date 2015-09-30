require 'discovery_service/metadata/updater'

RSpec.describe DiscoveryService::Metadata::Updater do
  context '#update' do
    let(:logger) { spy }
    let(:url) { 'http://saml-service.example.com/entities' }
    let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
    let(:config) do
      { saml_service: { uri: url },
        collections: { aaf: [%w(discovery aaf)],
                       edugain: [%w(discovery edugain)],
                       taukiri: [%w(discovery taukiri)],
                       ignored: [%w(discovery ignored)] } }
    end

    before do
      allow(Logger).to receive(:new).and_return(logger)
      allow(YAML).to receive(:load_file).and_return(config)
      stub_request(:get, url).to_return(response)
    end

    def run
      DiscoveryService::Metadata::Updater.new.update
    end

    context 'with valid saml service response' do
      include_context 'build_entity_data'

      context 'nothing stored in redis' do
        let(:matching_aaf_entity) do
          build_entity_data(%w(discovery idp aaf vho))
        end

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

        it 'stores all entities and page content' do
          run
          expect(redis.keys.to_set)
            .to eq(['entities:aaf', 'entities:edugain',
                    'pages:group:aaf', 'pages:group:edugain'].to_set)
        end

        it 'sets an expiry for all entities' do
          Timecop.freeze do
            run
            expect(redis.ttl('entities:aaf')).to(equal(28.days.to_i))
            expect(redis.ttl('entities:edugain')).to(equal(28.days.to_i))
          end
        end

        it 'stores each matching entity as a key value pair' do
          run
          expect(redis.get('entities:aaf'))
            .to eq([matching_aaf_entity].to_json)
          expect(redis.get('entities:edugain'))
            .to eq([matching_edugain_entity].to_json)
        end

        it 'stores each matching page content as a key value pair' do
          run
          expect(redis.get('pages:group:aaf'))
            .to include("#{matching_aaf_entity['name']}")
          expect(redis.get('pages:group:edugain'))
            .to include("#{matching_aaf_entity['name']}")
        end
      end

      context 'entities already stored in redis' do
        let(:original_ttl) { 10 }
        let(:existing_aaf_entity) do
          build_entity_data(%w(discovery idp aaf vho))
        end

        let(:existing_edugain_entity) do
          build_entity_data(%w(discovery idp edugain vho))
        end

        let(:existing_taukiri_entity) do
          build_entity_data(%w(discovery idp taukiri vho))
        end

        let(:existing_aaf_entities) { [existing_aaf_entity].to_json }
        let(:existing_aaf_page_content) { 'AAF page content here' }
        let(:existing_edugain_entities) { [existing_edugain_entity].to_json }
        let(:existing_edugain_page_content) { 'Edugain page content here' }
        let(:existing_taukiri_entities) { [existing_taukiri_entity].to_json }
        let(:existing_taukiri_page_content) { 'Taukiri page content here' }

        before do
          redis.set('entities:aaf', existing_aaf_entities)
          redis.set('pages:group:aaf', existing_aaf_page_content)
          redis.set('entities:edugain', existing_edugain_entities)
          redis.set('pages:group:edugain', existing_edugain_page_content)
          redis.set('entities:taukiri', existing_taukiri_entities)
          redis.set('pages:group:taukiri', existing_taukiri_page_content)
        end

        let(:new_aaf_entity) { build_entity_data(%w(discovery idp aaf vho)) }
        let(:new_entities) do
          [new_aaf_entity, existing_aaf_entity, existing_taukiri_entity]
        end

        let(:response_body) { { entities: new_entities } }
        let(:response) { { status: 200, body: JSON.generate(response_body) } }

        it 'only stores matching entities from the latest response' do
          run
          expect(redis.get('entities:aaf'))
            .to eq([new_aaf_entity, existing_aaf_entity].to_json)
          expect(redis.get('entities:taukiri'))
            .to eq([existing_taukiri_entity].to_json)
        end

        it 'only stores matching page content from the latest response' do
          run
          expect(redis.get('pages:group:aaf'))
            .to include("#{existing_aaf_entity['name']}")
          expect(redis.get('pages:group:aaf'))
            .to include("#{new_aaf_entity['name']}")
          expect(redis.get('pages:group:taukiri'))
            .to include("#{existing_taukiri_entity['name']}")
        end

        it 'only updates the ttl for entities contained in the response' do
          Timecop.freeze do
            redis.expire('entities:aaf', original_ttl)
            redis.expire('pages:group:aaf', original_ttl)
            redis.expire('entities:edugain', original_ttl)
            redis.expire('pages:group:edugain', original_ttl)
            redis.expire('entities:taukiri', original_ttl)
            redis.expire('pages:group:taukiri', original_ttl)
            run
            expect(redis.ttl('entities:aaf')).to(equal(28.days.to_i))
            expect(redis.ttl('pages:group:aaf')).to(equal(28.days.to_i))
            expect(redis.ttl('entities:taukiri')).to(equal(28.days.to_i))
            expect(redis.ttl('pages:group:taukiri')).to(equal(28.days.to_i))
            expect(redis.ttl('entities:edugain')).to(equal(original_ttl))
            expect(redis.ttl('pages:group:edugain')).to(equal(original_ttl))
          end
        end
      end

      context 'empty entity data' do
        let(:response_body) { { entities: [] } }

        let(:response) { { status: 200, body: JSON.generate(response_body) } }

        it 'stores nothing' do
          run
          expect(redis.keys).to eq([])
        end
      end
    end

    context 'with invalid (400) saml service response' do
      let(:response) { { status: 400, body: JSON.generate([]) } }

      it 'propagates the exception' do
        expect { run }.to raise_error(Net::HTTPServerException)
        expect(logger).to have_received(:error)
      end
    end
  end
end
