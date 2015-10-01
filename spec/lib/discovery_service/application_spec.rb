require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods

  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:app) { DiscoveryService::Application.new }

  context 'GET /discovery/:group' do
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
      let(:group_name) do
        "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-"
      end

      context 'when group exists' do
        include_context 'build_entity_data'

        let(:page_content) { 'Page content here' }

        before { redis.set("pages:group:#{group_name}", page_content) }

        it 'returns http status code 200' do
          run
          expect(last_response.status).to eq(200)
        end

        it 'shows content' do
          run
          expect(last_response.body).to eq(page_content)
        end
      end

      context 'when group does not exist' do
        it 'returns http status code 404' do
          run
          expect(last_response.status).to eq(404)
        end
      end
    end
  end
end
