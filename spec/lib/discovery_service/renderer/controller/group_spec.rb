require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/controller/group'

RSpec.describe DiscoveryService::Renderer::Controller::Group do
  describe '#generate_group_model(entities, lang)' do
    include_context 'build_entity_data'

    let(:klass) do
      Class.new { include DiscoveryService::Renderer::Controller::Group }
    end

    let(:environment) do
      { name: Faker::Lorem.word, status_uri: Faker::Internet.url }
    end

    let(:tag_groups) do
      [{ name: 'Australia', tag: 'au' },
       { name: 'New Zealand', tag: 'nz' },
       { name: 'International', tag: '*' }]
    end

    def run
      klass.new.generate_group_model(entities, lang, tag_groups, environment)
    end

    def expected_entity(entity_data, name = nil)
      { name: name.nil? ? entity_data[:names].first[:value] : name,
        entity_id: entity_data[:entity_id],
        logo_uri: entity_data[:logo_uri],
        description: entity_data[:description],
        domain: entity_data[:domain]
      }
    end

    subject { run }

    context 'with nil entities' do
      let(:entities) { nil }
      let(:lang) { Faker::Lorem.characters(2) }
      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it { is_expected.to eq([]) }
      end

      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end

      context 'the environment' do
        subject { run.environment }
        it 'is passed along' do
          expect(subject).to eq(environment)
        end
      end

      context 'the tag groups' do
        subject { run.tag_groups }
        it 'are passed along' do
          expect(subject).to eq(tag_groups)
        end
      end
    end

    context 'with empty entities' do
      let(:entities) { [] }
      let(:lang) { Faker::Lorem.characters(2) }
      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it { is_expected.to eq([]) }
      end

      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end

    context 'with one idp' do
      let(:idp) { build_entity_data(['idp']) }
      let(:entities) { [idp] }
      let(:lang) { idp[:names].first[:lang] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idp with name and entity id' do
          expect(subject)
            .to eq([expected_entity(idp)])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end

    context 'with entities without names' do
      let(:idp_without_names) { build_entity_data(['idp']).except(:names) }
      let(:sp_without_names) { build_entity_data(['sp']).except(:names) }
      let(:entities) { [idp_without_names, sp_without_names] }
      let(:lang) { Faker::Lorem.characters(2) }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idp with entity id as name' do
          expect(subject)
            .to eq([expected_entity(idp_without_names,
                                    idp_without_names[:entity_id])])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp with entity id as name' do
          expect(subject)
            .to eq([expected_entity(sp_without_names,
                                    sp_without_names[:entity_id])])
        end
      end
    end

    context 'with one idp and one sp' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:idp) { build_entity_data(['idp'], lang) }
      let(:sp) { build_entity_data(['sp'], lang) }

      let(:entities) { [idp, sp] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idp with name and entity id' do
          expect(subject)
            .to eq([expected_entity(idp)])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp with name and entity id' do
          expect(subject).to eq([expected_entity(sp)])
        end
      end
    end

    context 'multiple idps and sps' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:idp1) { build_entity_data(['idp'], lang) }
      let(:idp2) { build_entity_data(['idp'], lang) }
      let(:sp1) { build_entity_data(['sp'], lang) }
      let(:sp2) { build_entity_data(['sp'], lang) }

      let(:entities) { [idp1, sp1, idp2, sp2] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idps with name and entity id' do
          expect(subject)
            .to eq([expected_entity(idp1), expected_entity(idp2)])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sps with name and entity id' do
          expect(subject)
            .to eq([expected_entity(sp1), expected_entity(sp2)])
        end
      end
    end

    context 'with many idps of the same language' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:idp1) { build_entity_data(['idp'], lang) }
      let(:idp2) { build_entity_data(['idp'], lang) }

      let(:entities) { [idp1, idp2] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds all idps with name and entity id' do
          expect(subject)
            .to eq([expected_entity(idp1), expected_entity(idp2)])
        end
      end
      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end

    context 'with multiple idps of different languages' do
      let(:lang) { Faker::Lorem.characters(4) }
      let(:idp) { build_entity_data(['idp']) }
      let(:idp_with_matching_lang) { build_entity_data(['idp'], lang) }

      let(:entities) { [idp, idp_with_matching_lang] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'use the entity id for name when no language can be matched' do
          expect(subject)
            .to eq([expected_entity(idp, idp[:entity_id]),
                    expected_entity(idp_with_matching_lang)])
        end
      end
      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end
  end
end
