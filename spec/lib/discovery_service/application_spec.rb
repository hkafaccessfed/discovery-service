require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods
  include_context 'build_entity_data'

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
    let(:selected_idp) { Faker::Internet.url }
    let(:form_content) { { user_idp: selected_idp } }
    let(:requesting_sp) { Faker::Internet.url }

    def run
      post path, form_content
    end

    context 'when group is not configured' do
      before { run }
      let(:path) do
        "/discovery/#{group_name}?entity_id=#{requesting_sp}"
      end

      it 'returns http status code 404' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'with an entity id parameter, no return parameter and no'\
     ' discovery response stored' do
      let(:config) { { groups: {} } }

      let(:path) do
        "/discovery/#{group_name}?entity_id=#{requesting_sp}"
      end

      before do
        config[:groups][group_name.to_sym] = []
        run
      end

      it 'returns http status code 404' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'with an entity id parameter, no return parameter but discovery'\
     ' response stored' do
      let(:existing_entity) { build_entity_data(['sp', group_name]) }
      let(:requesting_sp) { existing_entity[:entity_id] }

      let(:path) do
        "/discovery/#{group_name}?entity_id=#{requesting_sp}"
      end

      before do
        redis.set("entities:#{group_name}",
                  to_hash([existing_entity]).to_json)
        config[:groups][group_name.to_sym] = []
        run
      end

      it 'returns http status code 302' do
        expect(last_response.status).to eq(302)
      end

      it 'redirects back to sp using discovery response value' do
        expect(last_response.location)
          .to eq("#{existing_entity[:discovery_response]}?"\
             "#{Rack::Utils.build_query(entityID: selected_idp)}")
      end
    end

    context 'with entity id and return parameter' do
      let(:sp_return_url) { Faker::Internet.url }

      let(:path) do
        "/discovery/#{group_name}?entity_id=#{requesting_sp}"\
        "&return=#{sp_return_url}"
      end

      let(:form_content) { { user_idp: selected_idp } }

      before do
        config[:groups][group_name.to_sym] = []
        run
      end

      it 'returns http status code 302' do
        expect(last_response.status).to eq(302)
      end

      it 'redirects back to sp using return url value' do
        expect(last_response.location)
          .to eq("#{sp_return_url}?"\
          "#{Rack::Utils.build_query(entityID: selected_idp)}")
      end
    end

    context 'with entity id parameter, return parameter and also a'\
      ' discovery response' do
      let(:sp_return_url) { Faker::Internet.url }
      let(:existing_entity) { build_entity_data(['sp', group_name]) }

      let(:path) do
        "/discovery/#{group_name}?entityID=#{requesting_sp}"\
        "&return=#{sp_return_url}"
      end

      before do
        config[:groups][group_name.to_sym] = []
        redis.set("entities:#{group_name}",
                  to_hash([existing_entity]).to_json)
        run
      end

      it 'returns http status code 302' do
        expect(last_response.status).to eq(302)
      end

      it 'ignores stored discovery response value and uses return parameter' do
        expect(last_response.location)
          .to eq("#{sp_return_url}?"\
          "#{Rack::Utils.build_query(entityID: selected_idp)}")
      end
    end
  end
end
