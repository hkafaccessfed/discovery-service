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

        let(:entity_data) { [build_entity_data(%w(discovery idp aaf vho))] }

        before { redis.set("entity_data:#{group_name}", entity_data.to_json) }

        it 'returns http status code 200' do
          run
          expect(last_response.status).to eq(200)
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
