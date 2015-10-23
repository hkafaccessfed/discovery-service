require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/controller/group'

RSpec.describe DiscoveryService::Renderer::Controller::Group do
  describe '#generate_group_model(entities, lang)' do
    include_context 'build_entity_data'

    let(:klass) do
      Class.new { include DiscoveryService::Renderer::Controller::Group }
    end

    def run
      klass.new.generate_group_model(entities, lang)
    end

    subject { run }

    context 'with nil entities' do
      let(:entities) { nil }
      let(:lang) { Faker::Lorem.characters(2) }
      it { is_expected.to_not be_nil }

      context 'generated entities' do
        subject { run.entities }
        it { is_expected.to eq([]) }
      end
    end

    context 'with empty entities' do
      let(:entities) { nil }
      let(:lang) { Faker::Lorem.characters(2) }
      it { is_expected.to_not be_nil }

      context 'generated entities' do
        subject { run.entities }
        it { is_expected.to eq([]) }
      end
    end

    context 'with one entity' do
      let(:entity) { build_entity_data }
      let(:entities) { [entity] }
      let(:lang) { entity[:names].first[:lang] }

      it { is_expected.to_not be_nil }

      context 'generated entities' do
        subject { run.entities }
        it 'builds entities as expected' do
          expect(subject)
            .to eq([{ name: entity[:names].first[:value],
                      entity_id: entity[:entity_id] }])
        end
      end
    end

    context 'with many entities of the same language' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:entity1) do
        build_entity_data([Faker::Lorem.word, Faker::Lorem.word], lang)
      end

      let(:entity2) do
        build_entity_data([Faker::Lorem.word, Faker::Lorem.word], lang)
      end

      let(:entities) { [entity1, entity2] }

      it { is_expected.to_not be_nil }

      context 'generated entities' do
        subject { run.entities }
        it 'builds all entities as expected' do
          expect(subject)
            .to eq([{ name: entity1[:names].first[:value],
                      entity_id: entity1[:entity_id] },
                    { name: entity2[:names].first[:value],
                      entity_id: entity2[:entity_id] }])
        end
      end
    end

    context 'with multiple entities of different languages' do
      let(:lang) { "#{Faker::Lorem.characters(4)}" }
      let(:entity) { build_entity_data }

      let(:entity_with_matching_lang) do
        build_entity_data([Faker::Lorem.word, Faker::Lorem.word], lang)
      end

      let(:entities) { [entity, entity_with_matching_lang] }

      it { is_expected.to_not be_nil }

      context 'generated entities' do
        subject { run.entities }
        it 'use the entity id for name when no lang can be matched' do
          expect(subject)
            .to eq([{ name: entity[:entity_id],
                      entity_id: entity[:entity_id] },
                    { name: entity_with_matching_lang[:names].first[:value],
                      entity_id: entity_with_matching_lang[:entity_id] }])
        end
      end
    end
  end
end
