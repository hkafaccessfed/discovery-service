require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods
  include_context 'build_entity_data'

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

  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  let(:app) { DiscoveryService::Application.new }
  let(:environment_name) { Faker::Lorem.word }
  let(:environment_status_url) { Faker::Internet.url }

  let(:config) do
    { groups: {}, environment:
        { name: environment_name, status_url: environment_status_url } }
  end

  before { allow(YAML).to receive(:load_file).and_return(config) }

  def configure_group
    config[:groups][group_name.to_sym] = []
  end

  describe 'GET /' do
    let(:path) { '/' }
    def run
      get path
    end

    it 'responds with status code 302' do
      run
      expect(last_response.status).to eq(302)
    end

    it 'redirects to /discovery' do
      run
      expect(last_response.location).to eq('http://example.org/discovery')
    end
  end

  describe 'GET /health' do
    def run
      get '/health'
    end

    it 'responds with status code 200' do
      run
      expect(last_response.status).to eq(200)
    end
  end

  describe 'GET /embedded_wayf' do
    let(:group_name) { 'aaf' }

    before do
      configure_group
      redis.set('entities:aaf', '{}')
    end

    def run
      get '/embedded_wayf'
    end

    it 'responds with a javascript document' do
      run
      expect(last_response.status).to eq(200)
      expect(last_response['Content-Type'])
        .to start_with('application/javascript')
      expect(last_response.body).to include('AAF Embedded WAYF')
    end
  end

  describe 'GET /discovery' do
    let(:path) { '/discovery' }
    let(:group_name) { "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-" }

    def run
      get path
    end

    context 'with no idps previously selected' do
      it 'shows that there are no organisations selected' do
        run
        expect(last_response.body)
          .to include('You have no saved organisations.')
      end

      it 'shows the environment name' do
        run
        expect(last_response.body).to include(environment_name)
      end

      it 'shows the status url' do
        run
        expect(last_response.body).to include(environment_status_url)
      end
    end

    context 'with idps previously selected' do
      context 'and the idp\'s group is gone' do
        let(:entity_id) { Faker::Internet.url }
        it 'shows that there are no organisations selected' do
          configure_group
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate('other_group' => entity_id)
          run
          expect(last_response.body)
            .to include('You have no saved organisations.')
        end
      end

      context 'and the idp does not exist anymore' do
        let(:entity_id) { Faker::Internet.url }
        it 'shows that there are no organisations selected' do
          configure_group
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate(group_name => entity_id)
          run
          expect(last_response.body)
            .to include('You have no saved organisations.')
        end
      end

      context 'and the idp and group do exist' do
        let(:existing_entity) { build_idp_data(['idp', group_name], 'en') }

        before do
          configure_group
          redis.set("entities:#{group_name}",
                    to_hash([existing_entity]).to_json)
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate(group_name => existing_entity[:entity_id])
          run
        end

        it 'shows the idp name' do
          expect(last_response.body)
            .to include(CGI.escapeHTML(existing_entity[:names].first[:value]))
        end

        it 'shows the idp logo' do
          expect(last_response.body)
            .to include(existing_entity[:logos].first[:url])
        end

        it 'contains a form to reset idps' do
          expect(last_response.body).to include("<form action=\"\" "\
            "method=\"POST\">")
        end

        it 'shows the help text header (singular)' do
          expect(last_response.body).to include('Your saved organisation')
        end

        it 'shows the help text body (singular)' do
          expect(last_response.body).to include('When you access a service, '\
          'you will be automatically sent to this organisation to log in.'\
          ' You can reset this, and you\'ll be asked to select your'\
          ' organisation next time you access a service.')
        end

        it 'shows the reset button' do
          expect(last_response.body).to include('Reset')
        end
      end

      context 'and multiple idp selections exist' do
        let(:other_group_name) do
          "#{Faker::Lorem.word}_#{Faker::Number.number(3)}-"
        end

        let(:existing_entity) { build_idp_data(['idp', group_name], 'en') }
        let(:other_entity) do
          build_idp_data(['idp', other_group_name], 'en')
        end

        before do
          configure_group
          config[:groups][other_group_name.to_sym] = []
          redis.set("entities:#{group_name}",
                    to_hash([existing_entity]).to_json)
          redis.set("entities:#{other_group_name}",
                    to_hash([other_entity]).to_json)
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate(group_name => existing_entity[:entity_id],
                            other_group_name => other_entity[:entity_id])
          run
        end

        it 'shows the idp names' do
          expect(last_response.body)
            .to include(CGI.escapeHTML(
                          existing_entity[:names].first[:value]))
          expect(last_response.body)
            .to include(CGI.escapeHTML(other_entity[:names].first[:value]))
        end

        it 'shows the idp logos' do
          expect(last_response.body)
            .to include(existing_entity[:logos].first[:url])
          expect(last_response.body)
            .to include(other_entity[:logos].first[:url])
        end

        it 'shows the help text header (plural)' do
          expect(last_response.body).to include('Your saved organisations')
        end

        it 'shows the help text body (plural)' do
          expect(last_response.body).to include('When you access a service, '\
          'you will be automatically sent to one of these organisations to'\
          ' log in. You can reset this, and you\'ll be asked to select your'\
          ' organisation next time you access a service.')
        end
      end

      context 'and the idp and group do exist but non \'en\' language' do
        let(:existing_entity) { build_idp_data(['idp', group_name]) }

        before do
          configure_group
          redis.set("entities:#{group_name}",
                    to_hash([existing_entity]).to_json)
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate(group_name => existing_entity[:entity_id])
          run
        end

        it 'shows the organisation (entity id)' do
          expect(last_response.body)
            .to include(CGI.escapeHTML(existing_entity[:entity_id]))
        end

        it 'does not show the idp logo' do
          expect(last_response.body)
            .to_not include(existing_entity[:logos].first[:url])
        end
      end
    end
  end

  describe 'POST /discovery' do
    let(:group_name) { "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-" }
    let(:originally_selected_idp) { Faker::Internet.url }

    let(:reset_cookie) do
      'selected_organisations=; max-age=0; '\
      'expires=Thu, 01 Jan 1970 00:00:00 -0000'
    end

    def run
      post '/discovery'
    end

    context 'when no idp selections are set' do
      it 'returns a status 200' do
        run
        expect(last_response.status).to eq(200)
      end

      it 'resets the idp selection cookies' do
        run
        expect(last_response['Set-Cookie']).to eq(reset_cookie)
      end

      it 'shows that there are no organisations selected' do
        run
        expect(last_response.body)
          .to include('You have no saved organisations.')
      end

      it 'shows the environment name' do
        run
        expect(last_response.body).to include(environment_name)
      end

      it 'shows the status url' do
        run
        expect(last_response.body).to include(environment_status_url)
      end
    end

    context 'when one idp selection is already set' do
      def set_cookie
        rack_mock_session.cookie_jar['selected_organisations'] =
            JSON.generate(group_name => originally_selected_idp)
      end

      it 'returns a status 200' do
        run
        expect(last_response.status).to eq(200)
      end

      it 'resets the idp selection cookies' do
        set_cookie
        run
        expect(last_response['Set-Cookie']).to eq(reset_cookie)
      end

      it 'shows that there are no organisations selected' do
        set_cookie
        run
        expect(last_response.body)
          .to include('You have no saved organisations.')
      end
    end

    context 'when multiple idp selections are already set' do
      def set_cookie
        rack_mock_session.cookie_jar['selected_organisations'] =
            JSON.generate(group_name => originally_selected_idp,
                          other_group_name => other_selected_idp)
      end

      let(:other_group_name) do
        "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-"
      end

      let(:other_selected_idp) { Faker::Internet.url }

      it 'returns a status 200' do
        run
        expect(last_response.status).to eq(200)
      end

      it 'resets the idp selection cookies' do
        set_cookie
        run
        expect(last_response['Set-Cookie']).to eq(reset_cookie)
      end

      it 'shows that there are no organisations selected' do
        set_cookie
        run
        expect(last_response.body)
          .to include('You have no saved organisations.')
      end
    end
  end

  describe 'GET /discovery/:group' do
    let(:path_for_group) { "/discovery/#{group_name}?entityID=#{entity_id}" }
    let(:entity_id) { Faker::Internet.url }
    let(:group_name) { Faker::Lorem.word }

    def run
      get path_for_group
    end

    context 'with an non url-safe base64 alphabet group name' do
      let(:group_name) { '@*!' }

      it 'returns http status code 400' do
        run
        expect(last_response.status).to eq(400)
      end
    end

    context 'with a non-configured group' do
      it 'returns http status code 404' do
        run
        expect(last_response.status).to eq(404)
      end
    end

    context 'with a configured group' do
      let(:id) { SecureRandom.urlsafe_base64 }

      before do
        configure_group
        expect(SecureRandom).to receive(:urlsafe_base64).and_return(id)
      end

      it 'redirects to a unique url with the query string' do
        run
        expect(last_response.status).to eq(302)
        uri = URI.parse(last_response.location)
        expect(uri.path).to match(%r{/discovery/#{group_name}/[a-zA-Z0-9_-]+})
        expect(URI.unescape(uri.query)).to eq("entityID=#{entity_id}")
      end

      it 'stores the id in redis' do
        Timecop.freeze do
          run
          expect(redis.get("id:#{id}").to_s).to eq('1')
          expect(redis.ttl("id:#{id}")).to eq(3600)
        end
      end

      it 'writes an audit log entry' do
        expect { run }.to change { redis.llen('audit') }.by(1)
        json = redis.lindex('audit', 0)
        data = JSON.parse(json, symbolize_names: true)
        expect(data[:unique_id]).to eq(id)
      end
    end
  end

  describe 'GET /discovery/:group/:unique_id' do
    let(:unique_id) { Faker::Lorem.words(2).join('-') }
    let(:path_for_group) { "/discovery/#{group_name}/#{unique_id}" }

    def run
      get path_for_group
    end

    context 'with an non url-safe base64 alphabet group name' do
      before { run }
      let(:group_name) { '@*!' }
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

      context 'with the idp selection set and entity id passed' do
        let(:entity_id) { Faker::Internet.url }
        let(:originally_selected_idp) { Faker::Internet.url }

        let(:path_for_group) do
          "/discovery/#{group_name}/#{unique_id}?entityID=#{entity_id}"
        end

        before do
          configure_group
          allow_any_instance_of(DiscoveryService::Application)
            .to receive(:handle_response).and_return('stubbed')
          rack_mock_session.cookie_jar['selected_organisations'] =
              JSON.generate(group_name => originally_selected_idp)
        end

        it 'handles the response' do
          run
          expect(last_response.body).to eq('stubbed')
        end

        it 'records an audit entry' do
          expect { run }.to change { redis.llen('audit') }.by(1)
          json = redis.lindex('audit', 0)
          data = JSON.parse(json, symbolize_names: true)
          expect(data).to include(unique_id: unique_id,
                                  selection_method: 'cookie')
        end
      end

      context 'with passive and return parameters' do
        let(:entity_id) { Faker::Internet.url }
        let(:sp_return_url) { Faker::Internet.url }
        let(:selected_idp) { Faker::Internet.url }
        let(:passive) { 'true' }

        let(:path_for_group) do
          "/discovery/#{group_name}/#{unique_id}?entityID=#{entity_id}"\
          "&isPassive=#{passive}&return=#{sp_return_url}"
        end

        context 'without cookies' do
          before do
            configure_group
            run
          end

          it 'returns http status code 302' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp using return url and no entity id' do
            expect_matching_response(sp_return_url, {})
          end
        end

        context 'with cookies' do
          before do
            configure_group
            rack_mock_session.cookie_jar['selected_organisations'] =
                JSON.generate(group_name => selected_idp)
            run
          end

          it 'returns http status code 302' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp with entity id because'\
             ' idp is resolved from cookies' do
            expect_matching_response(sp_return_url,
                                     'entityID' => selected_idp)
          end
        end
      end

      context 'with passive parameter but no return' do
        let(:entity_id) { Faker::Internet.url }
        let(:sp_return_url) { Faker::Internet.url }
        let(:selected_idp) { Faker::Internet.url }
        let(:passive) { 'true' }

        let(:path_for_group) do
          "/discovery/#{group_name}/#{unique_id}?entityID=#{entity_id}"\
          "&isPassive=#{passive}"
        end

        context 'without cookies' do
          before do
            configure_group
            run
          end

          it 'returns http status code 404 as no return found' do
            expect(last_response.status).to eq(404)
          end
        end

        context 'with cookies' do
          before do
            configure_group
            rack_mock_session.cookie_jar['selected_organisations'] =
                JSON.generate(group_name => selected_idp)
            run
          end

          it 'returns http status code 404 as no return found' do
            expect(last_response.status).to eq(404)
          end
        end

        context 'with cookies and discovery response stored' do
          let(:existing_entity) { build_sp_data(['sp', group_name]) }
          let(:entity_id) { existing_entity[:entity_id] }
          before do
            configure_group
            redis.set("entities:#{group_name}",
                      to_hash([existing_entity]).to_json)
            rack_mock_session.cookie_jar['selected_organisations'] =
                JSON.generate(group_name => existing_entity[:entity_id])
            run
          end

          it 'returns http status code 302 as discovery response is used' do
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp using discovery response value' do
            expect_matching_response(existing_entity[:discovery_response],
                                     'entityID' => existing_entity[:entity_id])
          end
        end
      end
    end
  end

  describe 'POST /discovery/:group/:unique_id' do
    let(:group_name) { Faker::Lorem.word }
    let(:selected_idp) { Faker::Internet.url }
    let(:form_content) { { user_idp: selected_idp } }
    let(:requesting_sp) { Faker::Internet.url }
    let(:sp_return_url) { Faker::Internet.url }
    let(:unique_id) { SecureRandom.urlsafe_base64 }
    let(:base_path) { "/discovery/#{group_name}/#{unique_id}" }

    def run
      post path, form_content
    end

    context 'when group is not configured' do
      before { run }
      let(:path) { "#{base_path}?entityID=#{requesting_sp}" }

      it 'returns http status code 404' do
        expect(last_response.status).to eq(404)
      end
    end

    context 'when group is configured' do
      before { configure_group }

      context 'without mandatory entity id parameter' do
        let(:path) { "#{base_path}" }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'without mandatory user idp form field' do
        let(:path) { "#{base_path}?entityID=#{requesting_sp}" }
        let(:form_content) { {} }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an invalid (non url) idp selection (form field)' do
        let(:path) { "#{base_path}?entityID=#{requesting_sp}" }
        let(:form_content) { { user_idp: '!@#ASDJK~##@!' } }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with invalid (non url) entity id' do
        let(:path) { "#{base_path}?entityID=!ASDASDJTK@" }

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an non url-safe base64 alphabet group name' do
        let(:group_name) { '@*!' }
        let(:path) do
          "#{base_path}?entityID=#{requesting_sp}"
        end

        before { run }

        it 'returns http status code 400' do
          expect(last_response.status).to eq(400)
        end
      end

      context 'with an entity id parameter, no return parameter and no'\
              ' discovery response stored' do
        let(:path) { "#{base_path}?entityID=#{requesting_sp}" }

        before { run }

        it 'returns http status code 404' do
          expect(last_response.status).to eq(404)
        end
      end

      context 'with an entity id parameter, no return parameter but discovery'\
              ' response stored' do
        let(:existing_entity) { build_sp_data(['sp', group_name]) }
        let(:requesting_sp) { existing_entity[:entity_id] }

        let(:path) { "#{base_path}?entityID=#{requesting_sp}" }

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
          "#{base_path}?entityID=#{requesting_sp}"\
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

      context 'with the option to remember organisation on' do
        let(:path) do
          "#{base_path}?entityID=#{requesting_sp}"\
          "&return=#{sp_return_url}"
        end

        def date_in_3_months
          (DateTime.now + 3.months).in_time_zone('UTC')
            .strftime('%a, %d %b %Y %H:%M:%S -0000')
        end

        def expected_cookie
          "selected_organisations=#{encoded_cookie};"\
                " path=/; expires=#{date_in_3_months}"
        end

        let(:form_content) { { user_idp: selected_idp, remember: 'on' } }
        let(:cookie_as_hash) { { group_name => selected_idp } }

        let(:encoded_cookie) do
          URI.encode_www_form_component(JSON.generate(cookie_as_hash))
        end

        context 'no idp selection previously' do
          it 'returns http status code 302' do
            run
            expect(last_response.status).to eq(302)
          end

          it 'redirects back to sp using return url value' do
            run
            expect_matching_response(sp_return_url, 'entityID' => selected_idp)
          end

          it 'sets a cookie for the selected idp' do
            Timecop.freeze do
              run
              expect(last_response['Set-Cookie']).to eq(expected_cookie)
            end
          end
        end

        context 'with a idp selection already saved' do
          let(:originally_selected_idp) { Faker::Internet.url }

          it 'overwrites the cookie for the selected idp' do
            Timecop.freeze do
              rack_mock_session.cookie_jar['selected_organisations'] =
                  JSON.generate(group_name => originally_selected_idp)
              run
              expect(last_response['Set-Cookie']).to eq(expected_cookie)
            end
          end
        end

        context 'with a idp selection already saved for another group' do
          let(:other_idp) { Faker::Internet.url }
          let(:other_group) do
            "#{Faker::Lorem.word}_#{Faker::Number.number(2)}-"
          end

          let(:other_selected_organisation_hash) do
            { other_group => other_idp }
          end

          let(:encoded_cookie) do
            URI.encode_www_form_component(
              JSON.generate(other_selected_organisation_hash.merge(
                              cookie_as_hash)))
          end

          it 'maintains the idp for the other group' do
            Timecop.freeze do
              rack_mock_session.cookie_jar['selected_organisations'] =
                  JSON.generate(other_selected_organisation_hash)
              run
              expect(last_response['Set-Cookie']).to eq(expected_cookie)
            end
          end
        end
      end

      context 'with entity id and return parameter containing a query' do
        let(:return_query) { CGI.escape('?a=b&c=d') }
        let(:sp_return_url_with_query) { "#{sp_return_url}#{return_query}" }
        let(:path) do
          "#{base_path}?entityID=#{requesting_sp}"\
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

        it 'records an audit entry' do
          json = redis.lindex('audit', 0)
          data = JSON.parse(json, symbolize_names: true)
          expect(data).to include(unique_id: unique_id,
                                  selection_method: 'manual')
        end
      end

      context 'with entity id, return and return id parameter' do
        let(:path) do
          "#{base_path}?entityID=#{requesting_sp}"\
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
          "#{base_path}?entityID=#{requesting_sp}"\
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

      context 'with entity id parameter, return parameter and also a'\
              ' discovery response' do
        let(:existing_entity) { build_sp_data(['sp', group_name]) }

        let(:path) do
          "#{base_path}?entityID=#{requesting_sp}&return=#{sp_return_url}"
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
