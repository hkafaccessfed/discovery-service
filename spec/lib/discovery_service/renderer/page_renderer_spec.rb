require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/model/group'

RSpec.describe DiscoveryService::Renderer::PageRenderer do
  context '#render(page, model)' do
    include_context 'build_entity_data'
    include_context 'stringify_keys'

    let(:klass) do
      Class.new { include DiscoveryService::Renderer::PageRenderer }
    end

    let(:group_name) { Faker::Lorem.word }
    let(:entity_1) do
      stringify_keys(build_entity_data(['test', 'idp', group_name, 'vho']))
    end

    let(:entity_2) do
      stringify_keys(build_entity_data(['test', 'idp', group_name, 'vho']))
    end

    subject do
      klass.new.render(:group,
                       DiscoveryService::Renderer::Model::Group.new(
                         [entity_1, entity_2]))
    end

    it 'includes the layout' do
      expect(subject).to include('<!DOCTYPE html>')
      expect(subject).to include('</html>')
    end

    it 'includes the title' do
      expect(subject).to include('<title>AAF Discovery Service</title>')
    end

    it 'includes the selection string' do
      expect(subject).to include('Select your IdP:')
    end

    it 'includes the entities' do
      expect(subject).to include(CGI.escapeHTML(entity_1[:name]))
      expect(subject).to include(CGI.escapeHTML(entity_2[:name]))
    end
  end
end
