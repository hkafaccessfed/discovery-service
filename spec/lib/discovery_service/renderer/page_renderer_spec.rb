require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/model/group'

RSpec.describe DiscoveryService::Renderer::PageRenderer do
  describe '#render(page, model)' do
    let(:klass) do
      Class.new { include DiscoveryService::Renderer::PageRenderer }
    end

    let(:environment) do
      { name: Faker::Lorem.word, status_uri: Faker::Internet.url }
    end

    let(:idps) { [] }
    let(:sps) { [] }

    subject do
      klass.new.render(:group,
                       DiscoveryService::Renderer::Model::Group.new(
                         idps, sps, environment))
    end

    it 'includes the layout' do
      expect(subject).to include('<!DOCTYPE html>')
      expect(subject).to include('</html>')
    end

    it 'includes the title' do
      expect(subject).to include('<title>AAF Discovery Service</title>')
    end

    it 'shows that there are no idps' do
      expect(subject).to include('No organisations to select')
    end

    it 'includes the link to status' do
      expect(subject)
        .to include("<a href=\"#{environment[:status_uri]}\""\
                           " target=\"_blank\">Federation Status</a>")
    end

    it 'includes the environment name' do
      expect(subject).to include("#{environment[:name]}")
    end

    context 'with idps' do
      let(:group_name) { Faker::Lorem.word }
      let(:select_button_class) do
        'button ui floated right button small primary'\
        ' select_organisation_button'
      end

      let(:idp_1) do
        { name: Faker::University.name, entity_id: Faker::Internet.url }
      end
      let(:idp_2) do
        { name: Faker::University.name, entity_id: Faker::Internet.url }
      end

      let(:idps) { [idp_1, idp_2] }

      let(:expected_open_form_tag) do
        '<form action="" id="idp_selection_form" method="POST">'
      end

      it 'includes the selection string' do
        expect(subject).to include('Search for your organisation')
      end

      it 'includes a form to submit idp selection' do
        expect(subject).to include(expected_open_form_tag)
      end

      it 'includes the organisations to select' do
        expect(subject).to include(CGI.escapeHTML(idp_1[:name]))
        expect(subject).to include(CGI.escapeHTML(idp_2[:name]))
      end

      it 'includes a submit button for each idp' do
        expect(subject).to include("<input class=\"#{select_button_class}\""\
          " name=\"#{idp_1[:entity_id]}\" type=\"submit\" value=\"Select\" />")
        expect(subject).to include("<input class=\"#{select_button_class}\""\
          " name=\"#{idp_2[:entity_id]}\" type=\"submit\" value=\"Select\" />")
      end

      it 'includes the main (javascript enabled) idp selection button' do
        expect(subject)
          .to include("<div class=\"ui floated right button large primary\""\
            " id=\"select_organisation_button\">")
      end
    end
  end
end
