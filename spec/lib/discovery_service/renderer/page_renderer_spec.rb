require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/model/group'

RSpec.describe DiscoveryService::Renderer::PageRenderer do
  describe '#render(page, model)' do
    let(:klass) do
      Class.new { include DiscoveryService::Renderer::PageRenderer }
    end

    let(:idps) { [] }
    let(:sps) { [] }

    subject do
      klass.new.render(:group,
                       DiscoveryService::Renderer::Model::Group.new(idps, sps))
    end

    it 'includes the layout' do
      expect(subject).to include('<!DOCTYPE html>')
      expect(subject).to include('</html>')
    end

    it 'includes the title' do
      expect(subject).to include('<title>AAF Discovery Service</title>')
    end

    it 'shows that there are no idps' do
      expect(subject).to include('No IdPs to select')
    end

    context 'with idps' do
      let(:group_name) { Faker::Lorem.word }
      let(:idp_1) do
        { name: Faker::University.name, entity_id: Faker::Internet.url }
      end
      let(:idp_2) do
        { name: Faker::University.name, entity_id: Faker::Internet.url }
      end

      let(:idps) { [idp_1, idp_2] }

      let(:expected_form) do
        expected_form_with_newlines = <<-EOF
<form action="" method="POST">
<select name="user_idp">
<option value="#{CGI.escapeHTML(idp_1[:entity_id])}">
#{CGI.escapeHTML(idp_1[:name])}</option>
<option value="#{CGI.escapeHTML(idp_2[:entity_id])}">
#{CGI.escapeHTML(idp_2[:name])}</option>
</select>
<input class="button" type="submit" value="Select" />
</form>
      EOF
        expected_form_with_newlines.delete("\n")
      end

      it 'includes the selection string' do
        expect(subject).to include('Select your IdP:')
      end

      it 'includes a form to submit idp selection' do
        expect(subject).to include(expected_form)
      end
    end
  end
end
