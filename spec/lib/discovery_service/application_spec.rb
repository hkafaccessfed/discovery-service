require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods

  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:app) { DiscoveryService::Application.new }
  let(:config) { { groups: {} } }

  before { allow(YAML).to receive(:load_file).and_return(config) }

  describe 'GET /discovery/:group' do
    let(:path_for_group) { "/discovery/#{group_name}" }

    def run
      get path_for_group
    end

    context 'with an non url-safe base64 alphabet group name' do
      before { run }
      let(:group_name) { '@#!' }
      it 'returns http status code 400' do
        expect(last_response.status).to eq(400)
      end
    end

    context 'with a url-safe base64 alphabet group name' do
      let(:page_content) { 'Page content here' }
      let(:group_name) { "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-" }

      context 'when group exists in redis and config' do
        include_context 'build_entity_data'

        let(:config) { { groups: {} } }

        before do
          config[:groups][group_name.to_sym] = []
          redis.set("pages:group:#{group_name}", page_content)
        end

        it 'returns http status code 200' do
          run
          expect(last_response.status).to eq(200)
        end

        it 'shows content' do
          run
          expect(last_response.body).to eq(page_content)
        end
      end

      context 'when group exists in redis but not config' do
        before { redis.set("pages:group:#{group_name}", page_content) }
        it 'returns http status code 404' do
          run
          expect(last_response.status).to eq(404)
        end
      end

      context 'when group exists in config but not redis' do
        let(:config) { { groups: {} } }
        before { config[:groups][group_name.to_sym] = [] }
        it 'returns http status code 404' do
          run
          expect(last_response.status).to eq(404)
        end
      end

      context 'when group does not exist in redis or config' do
        it 'returns http status code 404' do
          run
          expect(last_response.status).to eq(404)
        end
      end
    end
  end

  describe 'POST /discovery/:group' do
    let(:group_name) { Faker::Lorem.word }

    let(:return_url) { 'return_url' }
    let(:requesting_sp) { 'requesting_sp' }
    let(:selected_idp) { 'selected_idp' }

    let(:path) do
      "/discovery/#{group_name}?entityID=#{requesting_sp}&return=#{return_url}"
    end

    let(:form_content) { { user_idp: selected_idp } }

    def run
      post path, form_content
    end

    before { run }

    it 'returns http status code 302' do
      expect(last_response.status).to eq(302)
    end

    it 'redirects back to sp with entity id' do
      expect(last_response.location)
        .to eq("http://example.org/#{return_url}&entityID=#{selected_idp}")
    end
  end
end
