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

      context 'generated idps' do
        subject { run.idps }
        it { is_expected.to eq([]) }
      end

      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
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
            .to eq([{ name: idp[:names].first[:value],
                      entity_id: idp[:entity_id] }])
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
            .to eq([{ name: idp_without_names[:entity_id],
                      entity_id: idp_without_names[:entity_id] }])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp with entity id as name' do
          expect(subject)
            .to eq([{ name: sp_without_names[:entity_id],
                      entity_id: sp_without_names[:entity_id] }])
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
            .to eq([{ name: idp[:names].first[:value],
                      entity_id: idp[:entity_id] }])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp with name and entity id' do
          expect(subject)
            .to eq([{ name: sp[:names].first[:value],
                      entity_id: sp[:entity_id] }])
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
            .to eq([{ name: idp1[:names].first[:value],
                      entity_id: idp1[:entity_id] },
                    { name: idp2[:names].first[:value],
                      entity_id: idp2[:entity_id] }])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sps with name and entity id' do
          expect(subject)
            .to eq([{ name: sp1[:names].first[:value],
                      entity_id: sp1[:entity_id] },
                    { name: sp2[:names].first[:value],
                      entity_id: sp2[:entity_id] }])
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
            .to eq([{ name: idp1[:names].first[:value],
                      entity_id: idp1[:entity_id] },
                    { name: idp2[:names].first[:value],
                      entity_id: idp2[:entity_id] }])
        end
      end
      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end

    context 'with multiple idps of different languages' do
      let(:lang) { "#{Faker::Lorem.characters(4)}" }
      let(:idp) { build_entity_data(['idp']) }
      let(:idp_with_matching_lang) { build_entity_data(['idp'], lang) }

      let(:entities) { [idp, idp_with_matching_lang] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'use the entity id for name when no language can be matched' do
          expect(subject)
            .to eq([{ name: idp[:entity_id],
                      entity_id: idp[:entity_id] },
                    { name: idp_with_matching_lang[:names].first[:value],
                      entity_id: idp_with_matching_lang[:entity_id] }])
        end
      end
      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end
  end
end
