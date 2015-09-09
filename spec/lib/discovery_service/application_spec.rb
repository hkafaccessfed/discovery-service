require 'discovery_service/application'

RSpec.describe DiscoveryService::Application do
  include Rack::Test::Methods
  let(:app) { DiscoveryService::Application }

  context 'get /' do
    it 'returns the placeholder text' do
      get '/'
      expect(last_response.body).to eq('Discovery Service Home!')
    end
  end
end
