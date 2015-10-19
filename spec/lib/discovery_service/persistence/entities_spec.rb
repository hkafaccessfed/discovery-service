require 'discovery_service/persistence/entities'

RSpec.describe DiscoveryService::Persistence::Entities do
  let(:klass) do
    Class.new do
      include DiscoveryService::Persistence::Entities
    end
  end

  let(:entities_as_string) do
    <<-EOF
{
  "https://example.org/idp/shibboleth":
  {
    "sso_endpoint":"https://example.org/idp/profile/Shibboleth/SSO",
    "name":"AAF Virtual Home",
    "tags":["discovery","idp","aaf","vho"]
  },
  "https://example.org/shibboleth":
  {
    "discovery_response":"https://example.org/Shibboleth.sso/Login",
    "name":"AAF Virtual Home SP",
    "tags":["aaf","sp"]
  }
}
    EOF
  end

  describe '#build_entities(entities_as_string)' do
    let(:expected_entities) do
      { 'https://example.org/idp/shibboleth' =>
          { sso_endpoint: 'https://example.org/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho) },
        'https://example.org/shibboleth' =>
          { discovery_response: 'https://example.org/Shibboleth.sso/Login',
            name: 'AAF Virtual Home SP',
            tags: %w(aaf sp)
          }
      }
    end

    subject { klass.new.build_entities(entities_as_string) }
    it 'builds entities into a hash' do
      expect(subject).to eq(expected_entities)
    end
  end

  describe '#to_hash(entities)' do
    subject { klass.new.to_hash(entities) }
    context 'with empty entity data' do
      let(:entities) { [] }
      it 'converts entities into a empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'with entity data' do
      include_context 'build_entity_data'
      let(:entities) { [entity1, entity2] }
      let(:entity1) { build_entity_data(%w(discovery idp aaf vho)) }
      let(:entity2) { build_entity_data(%w(aaf sp)) }

      it 'converts entities into a hash keyed by entity id' do
        expect(subject)
          .to eq(entity1[:entity_id] =>
                     { discovery_response: entity1[:discovery_response],
                       name: entity1[:name],
                       tags: entity1[:tags] },
                 entity2[:entity_id] =>
                     { discovery_response: entity2[:discovery_response],
                       name: entity2[:name],
                       tags: entity2[:tags] })
      end
    end
  end
end
