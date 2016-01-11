RSpec.describe DiscoveryService::EmbeddedWAYF do
  let(:klass) do
    Class.new do
      include DiscoveryService::EmbeddedWAYF

      def initialize(entity_cache)
        @entity_cache = entity_cache
      end
    end
  end

  let(:entity_cache) do
    double(DiscoveryService::Persistence::EntityCache,
           entities_as_hash: entities_as_hash)
  end

  subject { klass.new(entity_cache) }

  describe '#embedded_wayf_javascript' do
    let(:output) { subject.embedded_wayf_javascript }

    let(:expected_entities) do
      [
        {
          entity_id: 'http://test1.example.edu/idp/shibboleth',
          name: 'Example IdP 1'
        },
        {
          entity_id: 'http://test2.example.edu/idp/shibboleth',
          name: 'Example IdP 2'
        }
      ]
    end

    let(:entities_as_hash) do
      expected_entities.reduce({}) do |a, e|
        attrs = {
          names: [
            { value: 'wrong', lang: 'fr' },
            { value: e[:name], lang: 'en' }
          ]
        }
        a.merge(e[:entity_id] => attrs)
      end
    end

    it 'begins with a preamble' do
      expect(output)
        .to include('The AAF Embedded WAYF is deprecated and will be removed')
    end

    it 'renders a javascript IIFE' do
      expect(output).to match(%r{/\*.+\*/.*\(function\(\) \{.*\}\)\(\)\;$}m)
    end

    it 'includes the entities' do
      json = /var idp_entities = (\[.*?\]);/m.match(output)[1]
      expect(JSON.parse(json, symbolize_names: true))
        .to eq(expected_entities)
    end

    context 'with a missing name' do
      let(:entities_as_hash) do
        expected_entities.reduce({}) do |a, e|
          attrs = {
            names: [
              { value: 'wrong', lang: 'fr' }
            ]
          }
          a.merge(e[:entity_id] => attrs)
        end
      end

      it 'uses the entity id as the name' do
        json = /var idp_entities = (\[.*?\]);/m.match(output)[1]
        expect(JSON.parse(json, symbolize_names: true))
          .to eq(expected_entities.map { |e| e.merge(name: e[:entity_id]) })
      end
    end
  end
end
