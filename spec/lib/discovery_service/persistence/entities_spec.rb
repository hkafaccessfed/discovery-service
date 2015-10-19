require 'discovery_service/persistence/entities'

RSpec.describe DiscoveryService::Persistence::Entities do
  let(:klass) do
    Class.new do
      include DiscoveryService::Persistence::Entities
    end
  end
end
