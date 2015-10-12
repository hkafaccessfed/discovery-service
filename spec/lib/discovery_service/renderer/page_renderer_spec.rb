require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/model/group'

RSpec.describe DiscoveryService::Renderer::PageRenderer do
  describe '#render(page, model)' do
    include_context 'build_entity_data'

    let(:klass) do
      Class.new { include DiscoveryService::Renderer::PageRenderer }
    end

    let(:entities) { [] }

    subject do
      klass.new.render(:group,
                       DiscoveryService::Renderer::Model::Group.new(
                         entities))
    end

    it 'includes the layout' do
      expect(subject).to include('<!DOCTYPE html>')
      expect(subject).to include('</html>')
    end

    it 'includes the title' do
      expect(subject).to include('<title>AAF Discovery Service</title>')
    end

    it 'shows that there are no entities' do
      expect(subject).to include('No IdPs to select')
    end

    context 'with entities' do
      let(:group_name) { Faker::Lorem.word }
      let(:entity_1) { build_entity_data(['test', 'idp', group_name, 'vho']) }
      let(:entity_2) { build_entity_data(['test', 'idp', group_name, 'vho']) }

      let(:entities) { [entity_1, entity_2] }

      let(:expected_form) do
        expected_form_with_newlines = <<-EOF
<form action="" method="POST">
<select name="user_idp">
<option value="#{CGI.escapeHTML(entity_1[:entity_id])}">
#{CGI.escapeHTML(entity_1[:name])}</option>
<option value="#{CGI.escapeHTML(entity_2[:entity_id])}">
#{CGI.escapeHTML(entity_2[:name])}</option>
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
