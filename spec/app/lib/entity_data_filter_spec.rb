require 'lib/entity_data_filter'

RSpec.describe DiscoveryService::EntityDataFilter do
  context '#filter' do
    subject do
      DiscoveryService::EntityDataFilter.filter(entity_data, tag_config)
    end

    context 'with empty arguments' do
      let(:entity_data) { {} }
      let(:tag_config) { {} }

      it 'returns empty hash' do
        expect(subject).to eq({})
      end
    end

    context 'with an empty tag config' do
      let(:entity_data) do
        [
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        ]
      end
      let(:tag_config) { {} }

      it 'filters everything out' do
        expect(subject).to eq({})
      end
    end

    context 'with one tag' do
      let(:tag_config) { { aaf: [%w(discovery aaf)] } }
      context 'and one matching entity' do
        let(:matching_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:entity_data) { [matching_entity] }
        it 'returns the matching entity' do
          expect(subject).to eq(aaf: [matching_entity])
        end
      end

      context 'and one matching entity amongst many' do
        let(:matching_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:other_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(random idp aaf vho)
          }
        end
        let(:entity_data) { [matching_entity, other_entity] }

        it 'returns the matching entity only' do
          expect(subject).to eq(aaf: [matching_entity])
        end
      end

      context 'and no matching entities amongst many' do
        let(:first_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp tuakiri vho)
          }
        end
        let(:second_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(random idp aaf vho)
          }
        end
        let(:entity_data) { [first_entity, second_entity] }

        it 'returns an empty hash' do
          expect(subject).to eq({})
        end
      end

      context 'and multiple matching entities' do
        let(:first_match) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:second_match) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:other_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp taukiri vho)
          }
        end
        let(:entity_data) do
          [first_match, second_match, other_entity]
        end

        it 'returns all matching entities' do
          expect(subject).to eq(aaf: [first_match, second_match])
        end
      end
    end

    context 'with multiple tags' do
      let(:tag_config) do
        {
          aaf: [%w(discovery aaf)],
          edugain: [%w(discovery aaf), %w(discovery edugain)]
        }
      end
      context 'and one matching entity' do
        let(:matching_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp edugain vho)
          }
        end
        let(:entity_data) { [matching_entity] }
        it 'returns the matching entity' do
          expect(subject).to eq(edugain: [matching_entity])
        end
      end

      context 'and one matching entity amongst many' do
        let(:matching_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:other_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(random idp aaf vho)
          }
        end
        let(:entity_data) { [matching_entity, other_entity] }

        it 'returns the matching entity only' do
          expect(subject).to eq(aaf: [matching_entity],
                                edugain: [matching_entity])
        end
      end

      context 'and no matching entities amongst many' do
        let(:first_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp tuakiri vho)
          }
        end
        let(:second_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(random idp aaf vho)
          }
        end
        let(:entity_data) { [first_entity, second_entity] }

        it 'returns an empty hash' do
          expect(subject).to eq({})
        end
      end

      context 'and multiple matching entities' do
        let(:first_match) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:second_match) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp aaf vho)
          }
        end
        let(:third_match) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp edugain vho)
          }
        end
        let(:other_entity) do
          {
            entity_id: 'https://vho.test.aaf.edu.au/idp/shibboleth',
            sso_endpoint: 'https://vho.test.aaf.edu.au/idp/profile/Shibboleth/SSO',
            name: 'AAF Virtual Home',
            tags: %w(discovery idp taukiri vho)
          }
        end
        let(:entity_data) do
          [first_match, second_match, third_match, other_entity]
        end

        it 'returns all matching entities in groups' do
          expect(subject).to eq(aaf: [first_match, second_match],
                                edugain: [first_match, second_match,
                                          third_match])
        end
      end
    end
  end
end
