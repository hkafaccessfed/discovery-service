require 'discovery_service/metadata/updater'

RSpec.describe DiscoveryService::Metadata::Updater do
  describe '#update' do
    let(:logger) { spy }
    let(:url) { 'http://saml-service.example.com/entities' }
    let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
    let(:config) do
      { saml_service: { uri: url },
        groups: { aaf: [%w(discovery aaf)],
                  edugain: [%w(discovery edugain)],
                  taukiri: [%w(discovery taukiri)] } }
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
      let(:expiry) { 28.days.to_i }
      include_context 'build_entity_data'

      context 'that is empty' do
        let(:response_body) { {} }

        let(:response) { { status: 200, body: JSON.generate(response_body) } }

        it 'stores entity and page key value pairs' do
          run
          expect(redis.keys.to_set)
            .to eq(['entities:aaf', 'entities:edugain', 'entities:taukiri',
                    'pages:group:edugain', 'pages:group:aaf',
                    'pages:group:taukiri'].to_set)
        end

        it 'stores each entity as an empty hash' do
          run
          expect(redis.get('entities:aaf')).to eq({}.to_json)
          expect(redis.get('entities:edugain')).to eq({}.to_json)
        end

        it 'stores an empty page for each configured tag' do
          run
          expect(redis.get('pages:group:aaf')).to include('No IdPs to select')
          expect(redis.get('pages:group:edugain'))
            .to include('No IdPs to select')
          expect(redis.get('pages:group:taukiri'))
            .to include('No IdPs to select')
        end
      end

      context 'that contains no identity or service providers' do
        let(:response_body) do
          { identity_providers: [], service_providers: [] }
        end

        let(:response) { { status: 200, body: JSON.generate(response_body) } }

        it 'stores entity and page key value pairs' do
          run
          expect(redis.keys.to_set)
            .to eq(['entities:aaf', 'entities:edugain', 'entities:taukiri',
                    'pages:group:edugain', 'pages:group:aaf',
                    'pages:group:taukiri'].to_set)
        end

        it 'stores each entity as an empty hash' do
          run
          expect(redis.get('entities:aaf')).to eq({}.to_json)
          expect(redis.get('entities:edugain')).to eq({}.to_json)
        end

        it 'stores an empty page for each configured tag' do
          run
          expect(redis.get('pages:group:aaf')).to include('No IdPs to select')
          expect(redis.get('pages:group:edugain'))
            .to include('No IdPs to select')
          expect(redis.get('pages:group:taukiri'))
            .to include('No IdPs to select')
        end
      end

      context 'that contains identity and service providers' do
        context 'nothing stored in redis' do
          let(:matching_aaf_entity) do
            build_entity_data(%w(discovery idp aaf vho), 'en')
          end

          let(:matching_edugain_entity) do
            build_entity_data(%w(discovery sp edugain), 'en')
          end
          let(:non_matching_tuakiri_entity) do
            build_entity_data(%w(discovery idp tuakiri vho))
          end

          let(:response_body) do
            { identity_providers: [matching_aaf_entity,
                                   non_matching_tuakiri_entity],
              service_providers: [matching_edugain_entity] }
          end

          let(:response) { { status: 200, body: JSON.generate(response_body) } }

          it 'stores all entities and page content' do
            run
            expect(redis.keys.to_set)
              .to eq(['entities:aaf', 'entities:edugain', 'entities:taukiri',
                      'pages:group:edugain', 'pages:group:aaf',
                      'pages:group:taukiri'].to_set)
          end

          it 'sets an expiry for all entities' do
            Timecop.freeze do
              run
              expect(redis.ttl('entities:aaf')).to(equal(expiry))
              expect(redis.ttl('entities:edugain')).to(equal(expiry))
            end
          end

          it 'stores each matching entity as a key value pair' do
            run
            expect(redis.get('entities:aaf'))
              .to eq(to_hash([matching_aaf_entity]).to_json)
            expect(redis.get('entities:edugain'))
              .to eq(to_hash([matching_edugain_entity]).to_json)
          end

          it 'stores each matching page content as a key value pair' do
            run
            expect(redis.get('pages:group:aaf'))
              .to include(CGI.escapeHTML(
                            matching_aaf_entity[:names].first[:value]))
          end
        end

        context 'entities already stored in redis' do
          let(:original_ttl) { 10 }
          let(:aaf_entity) do
            build_entity_data(%w(discovery idp aaf), 'en')
          end

          let(:edugain_entity) do
            build_entity_data(%w(discovery idp edugain vho), 'en')
          end

          let(:taukiri_entity) do
            build_entity_data(%w(discovery idp taukiri vho), 'en')
          end

          let(:aaf_entities) { to_hash([aaf_entity]).to_json }
          let(:aaf_page_content) { 'Original AAF page content here' }
          let(:edugain_entities) { to_hash([edugain_entity]).to_json }
          let(:edugain_page_content) { 'Original Edugain page content here' }
          let(:taukiri_entities) { to_hash([taukiri_entity]).to_json }
          let(:taukiri_page_content) { 'Original Taukiri page content here' }
          let(:unconfigured_entities) { {}.to_json }
          let(:unconfigured_page_content) do
            'Unconfigured group page content here'
          end

          before do
            redis.set('entities:aaf', aaf_entities)
            redis.set('pages:group:aaf', aaf_page_content)
            redis.set('entities:edugain', edugain_entities)
            redis.set('pages:group:edugain', edugain_page_content)
            redis.set('entities:taukiri', taukiri_entities)
            redis.set('pages:group:taukiri', taukiri_page_content)
            redis.set('entities:unconfigured', unconfigured_entities)
            redis.set('pages:group:unconfigured',
                      unconfigured_page_content)
          end

          let(:new_aaf_entity) do
            build_entity_data(%w(discovery idp aaf vho), 'en')
          end

          let(:response_body) do
            { identity_providers: [new_aaf_entity, taukiri_entity],
              service_providers: [aaf_entity] }
          end

          let(:response) { { status: 200, body: JSON.generate(response_body) } }

          it 'only stores matching entities from the latest response' do
            run
            expect(redis.get('entities:aaf'))
              .to eq(to_hash([new_aaf_entity, aaf_entity]).to_json)
            expect(redis.get('entities:taukiri'))
              .to eq(to_hash([taukiri_entity]).to_json)
          end

          it 'only stores matching page content from the latest response' do
            run
            expect(redis.get('pages:group:aaf'))
              .to include(CGI.escapeHTML(aaf_entity[:names].first[:value]))
            expect(redis.get('pages:group:aaf'))
              .to include(CGI.escapeHTML(new_aaf_entity[:names].first[:value]))
            expect(redis.get('pages:group:taukiri')).to eq(taukiri_page_content)
          end

          it 'only updates the ttl for entities contained in the response' do
            Timecop.freeze do
              redis.expire('entities:aaf', original_ttl)
              redis.expire('pages:group:aaf', original_ttl)
              redis.expire('entities:edugain', original_ttl)
              redis.expire('pages:group:edugain', original_ttl)
              redis.expire('entities:taukiri', original_ttl)
              redis.expire('pages:group:taukiri', original_ttl)

              redis.expire('entities:unconfigured', original_ttl)
              redis.expire('pages:group:unconfigured', original_ttl)

              run

              expect(redis.ttl('entities:aaf')).to(equal(expiry))
              expect(redis.ttl('pages:group:aaf')).to(equal(expiry))
              expect(redis.ttl('entities:taukiri')).to(equal(expiry))
              expect(redis.ttl('pages:group:taukiri')).to(equal(expiry))
              expect(redis.ttl('entities:edugain')).to(equal(expiry))
              expect(redis.ttl('pages:group:edugain')).to(equal(expiry))

              expect(redis.ttl('entities:unconfigured')).to(equal(original_ttl))
              expect(redis.ttl('pages:group:unconfigured'))
                .to(equal(original_ttl))
            end
          end
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
