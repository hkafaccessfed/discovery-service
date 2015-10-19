require 'discovery_service/persistence/entity_cache'

RSpec.describe DiscoveryService::Persistence::EntityCache do
  let(:redis) { Redis::Namespace.new(:discovery_service, redis: Redis.new) }
  subject { DiscoveryService::Persistence::EntityCache.new(redis) }
end
