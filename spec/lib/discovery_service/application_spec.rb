require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods
  include_context 'build_entity_data'

  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:app) { DiscoveryService::Application.new }
  let(:config) { { groups: {} } }

  before { allow(YAML).to receive(:load_file).and_return(config) }

  def configure_group
    config[:groups][group_name.to_sym] = []
  end

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
          configure_group
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
        before { configure_group }
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
    def actual_params
      Rack::Utils.parse_nested_query(URI.parse(last_response.location).query)
    end

    def actual_location
      last_response.location.split('?').first
    end

    def expect_matching_response(expected_location, expected_params)
      expect(actual_location).to eq(expected_location)
      expect(actual_params).to eq(expected_params)
    end

    let(:group_name) { Faker::Lorem.word }
    let(:selected_idp) { Faker::Internet.url }
    let(:form_content) { { user_idp: selected_idp } }
    let(:requesting_sp) { Faker::Internet.url }
    let(:sp_return_url) { Faker::Internet.url }

    def run
      post path, form_content
    end

    context 'when group is not configured' do
      before { run }
      let(:path) { "/discovery/#{group_name}?entityID=#{requesting_sp}" }

      it 'returns http status code 404' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'when group is configured' do
      before { configure_group }

      context 'without mandatory entity id parameter' do
        let(:path) { "/discovery/#{group_name}" }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'without mandatory user idp form field' do
        let(:path) { "/discovery/#{group_name}?entityID=#{requesting_sp}" }
        let(:form_content) { {} }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an invalid (non url) idp selection (form field)' do
        let(:path) { "/discovery/#{group_name}?entityID=#{requesting_sp}" }
        let(:form_content) { { user_idp: '!@#ASDJK~##@!' } }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with invalid (non url) entity id' do
        let(:path) { "/discovery/#{group_name}?entityID=!ASDASDJTK@" }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an non url-safe base64 alphabet group name' do
        let(:group_name) { '@#!' }
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"
        end

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an entity id parameter, no return parameter and no'\
              ' discovery response stored' do
        let(:path) { "/discovery/#{group_name}?entityID=#{requesting_sp}" }

        before { run }

        it 'returns http status code 404' do
          expect(last_response.status).to eq(404)
        end
      end

      context 'with an entity id parameter, no return parameter but discovery'\
              ' response stored' do
        let(:existing_entity) { build_sp_data(['sp', group_name]) }
        let(:requesting_sp) { existing_entity[:entity_id] }

        let(:path) { "/discovery/#{group_name}?entityID=#{requesting_sp}" }

        before do
          redis.set("entities:#{group_name}",
                    to_hash([existing_entity]).to_json)
          run
        end

        it 'returns http status code 302' do
          expect(last_response.status).to eq(302)
        end

        it 'redirects back to sp using discovery response value' do
          expect_matching_response(existing_entity[:discovery_response],
                                   'entityID' => selected_idp)
        end
      end

      context 'with entity id and return parameter' do
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}"
        end

        before { run }

        it 'returns http status code 302' do
          expect(last_response.status).to eq(302)
        end

        it 'redirects back to sp using return url value' do
          expect_matching_response(sp_return_url, 'entityID' => selected_idp)
        end
      end

      context 'with entity id and return parameter containing a query' do
        let(:return_query) { CGI.escape('?a=b&c=d') }
        let(:sp_return_url_with_query) { "#{sp_return_url}#{return_query}" }
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url_with_query}"
        end

        before { run }

        it 'returns http status code 302' do
          expect(last_response.status).to eq(302)
        end

        it 'redirects back to sp using return url value' do
          expect_matching_response(sp_return_url,
                                   'entityID' => selected_idp,
                                   'a' => 'b',
                                   'c' => 'd')
        end
      end

      context 'with entity id, return and return id parameter' do
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}&returnIDParam=myCustomEntityID"
        end

        before { run }

        it 'returns http status code 302' do
          expect(last_response.status).to eq(302)
        end

        it 'redirects back to sp using return url value and custom entity id' do
          expect_matching_response(sp_return_url,
                                   'myCustomEntityID' => selected_idp)
        end
      end

      context 'with entity id, return and policy parameter' do
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}&policy=#{policy}"
        end

        before { run }

        context 'with unsupported policy' do
          let(:policy) { 'unsupported_policy ' }
          it 'returns http status code 400' do
            expect(last_response.status).to eq(400)
          end
        end

        context 'with supported policy' do
          let(:policy) do
            'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol:single'
          end

          it 'returns http status code 302' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp using return url value' do
            expect_matching_response(sp_return_url, 'entityID' => selected_idp)
          end
        end
      end

      context 'with entity id, return and passive parameter' do
        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}&isPassive=#{passive}"
        end

        before { run }

        context 'with passive set to true' do
          let(:passive) { 'true' }
          it 'returns http status code 302' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp without entity id because'\
             ' idp cannot be resolved from cookies/storage' do
            expect(last_response.location).to eq(sp_return_url)
          end
        end

        context 'with passive set to false' do
          let(:passive) { 'false' }
          it 'returns http status code 302' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp using return url value and entity id' do
            expect_matching_response(sp_return_url, 'entityID' => selected_idp)
          end
        end
      end

      context 'with entity id parameter, return parameter and also a'\
              ' discovery response' do
        let(:existing_entity) { build_sp_data(['sp', group_name]) }

        let(:path) do
          "/discovery/#{group_name}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}"
        end

        before do
          redis.set("entities:#{group_name}",
                    to_hash([existing_entity]).to_json)
          run
        end

        it 'returns http status code 302' do
          expect(last_response.status).to eq(302)
        end

        it 'ignores stored discovery response value and uses return param' do
          expect_matching_response(sp_return_url, 'entityID' => selected_idp)
        end
      end
    end
  end
end
