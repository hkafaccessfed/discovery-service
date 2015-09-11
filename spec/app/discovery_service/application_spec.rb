require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods
  let(:app) { DiscoveryService::Application }

  context 'get /' do
    it 'returns http status code 200' do
      get '/'
      expect(last_response.status).to eq(200)
    end
  end
end
