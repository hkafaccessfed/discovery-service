require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods

  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:app) { DiscoveryService::Application.new }

  context 'GET /discovery/:group' do
    context 'retrieves a group' do
      let(:group_name) { Faker::Lorem.word }
      let(:path_for_group) { "/discovery/#{group_name}" }

      def run
        get path_for_group
      end

      context 'when it exists' do
        include_context 'build_entity_data'

        let(:page_content) { 'Page content here' }

        before { redis.set("pages:index:#{group_name}", page_content) }

        it 'returns http status code 200' do
          run
          expect(last_response.status).to eq(200)
        end

        it 'shows content' do
          run
          expect(last_response.body).to eq(page_content)
        end
      end

      context 'when it does not exist' do
        it 'returns http status code 404' do
          run
          expect(last_response.status).to eq(404)
        end
      end
    end
  end
end
