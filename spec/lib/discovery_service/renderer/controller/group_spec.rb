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
      [{ name: Faker::Address.country, tag: Faker::Address.country_code },
       { name: Faker::Address.country, tag: Faker::Address.country_code },
       { name: Faker::Address.country, tag: '*' }]
    end

    def run
      klass.new.generate_group_model(entities, lang, tag_groups, environment)
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

    context 'with entities without names' do
      let(:lang) { Faker::Lorem.characters(2) }
      let(:idp_without_names) { build_idp_data(['idp'], lang).except(:names) }
      let(:sp_without_names) { build_sp_data(['sp'], lang).except(:names) }
      let(:entities) { [idp_without_names, sp_without_names] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idp with entity id as name' do
          expect(subject.first[:name]).to eq(idp_without_names[:entity_id])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp with entity id as name' do
          expect(subject.first[:name]).to eq(sp_without_names[:entity_id])
        end
      end
    end

    context 'with one idp and one sp' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:idp) { build_idp_data(['idp'], lang) }
      let(:sp) { build_sp_data(['sp'], lang) }

      let(:entities) { [idp, sp] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idp as expected' do
          expect(subject).to eq([{ entity_id: idp[:entity_id],
                                   tags: idp[:tags],
                                   name: idp[:names].first[:value],
                                   logo_uri: idp[:logos].first[:uri],
                                   description:
                                       idp[:descriptions].first[:value],
                                   geolocations: idp[:geolocations] }])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sp as expected' do
          expect(subject).to eq([{ entity_id: sp[:entity_id],
                                   tags: sp[:tags],
                                   name: sp[:names].first[:value],
                                   logo_uri: sp[:logos].first[:uri],
                                   description: sp[:descriptions].first[:value],
                                   information_uri:
                                       sp[:information_uris].first[:uri],
                                   privacy_statement_uri:
                                       sp[:privacy_statement_uris].first[:uri]
                                 }])
        end
      end
    end

    context 'multiple idps and sps' do
      let(:lang) { Faker::Lorem.characters(2) }

      let(:idp1) { build_idp_data(['idp'], lang) }
      let(:idp2) { build_idp_data(['idp'], lang) }
      let(:sp1) { build_sp_data(['sp'], lang) }
      let(:sp2) { build_sp_data(['sp'], lang) }

      let(:entities) { [idp1, sp1, idp2, sp2] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idps as expected' do
          expect(subject)
            .to eq([{ entity_id: idp1[:entity_id],
                      tags: idp1[:tags],
                      name: idp1[:names].first[:value],
                      logo_uri: idp1[:logos].first[:uri],
                      description: idp1[:descriptions].first[:value],
                      geolocations: idp1[:geolocations] },
                    { entity_id: idp2[:entity_id],
                      tags: idp2[:tags],
                      name: idp2[:names].first[:value],
                      logo_uri: idp2[:logos].first[:uri],
                      description: idp2[:descriptions].first[:value],
                      geolocations: idp2[:geolocations] }])
        end
      end

      context 'generated sps' do
        subject { run.sps }
        it 'builds sps as expected' do
          expect(subject)
            .to eq([{ entity_id: sp1[:entity_id],
                      tags: sp1[:tags],
                      name: sp1[:names].first[:value],
                      logo_uri: sp1[:logos].first[:uri],
                      description: sp1[:descriptions].first[:value],
                      information_uri: sp1[:information_uris].first[:uri],
                      privacy_statement_uri:
                          sp1[:privacy_statement_uris].first[:uri] },
                    { entity_id: sp2[:entity_id],
                      tags: sp2[:tags],
                      name: sp2[:names].first[:value],
                      logo_uri: sp2[:logos].first[:uri],
                      description: sp2[:descriptions].first[:value],
                      information_uri: sp2[:information_uris].first[:uri],
                      privacy_statement_uri:
                          sp2[:privacy_statement_uris].first[:uri] }])
        end
      end
    end

    context 'with multiple idps of different languages' do
      let(:lang) { Faker::Lorem.characters(4) }
      let(:idp) { build_idp_data(['idp']) }
      let(:idp_with_matching_lang) { build_idp_data(['idp'], lang) }

      let(:entities) { [idp, idp_with_matching_lang] }

      it { is_expected.to_not be_nil }

      context 'generated idps' do
        subject { run.idps }
        it 'builds idps as expected' do
          expect(subject)
            .to eq([{ entity_id: idp[:entity_id],
                      tags: idp[:tags],
                      name: idp[:entity_id],
                      geolocations: idp[:geolocations] },
                    { entity_id: idp_with_matching_lang[:entity_id],
                      tags: idp_with_matching_lang[:tags],
                      name: idp_with_matching_lang[:names].first[:value],
                      logo_uri: idp_with_matching_lang[:logos].first[:uri],
                      description:
                          idp_with_matching_lang[:descriptions].first[:value],
                      geolocations: idp_with_matching_lang[:geolocations] }])
        end
      end
      context 'generated sps' do
        subject { run.sps }
        it { is_expected.to eq([]) }
      end
    end
  end
end
