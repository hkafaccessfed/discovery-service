require 'json'
require 'active_support/core_ext/hash'

module DiscoveryService
  module Persistence
    # Collection of methods to build entity data (from / to) redis
    module Entities
      def build_entities(entities_as_string)
        stored_entities_as_json = JSON.parse(entities_as_string)
        stored_entities_as_json.deep_symbolize_keys!
      end

      def to_hash(entities)
        hash = Hash[entities.map { |e| [e[:entity_id], e.except(:entity_id)] }]
        hash.deep_symbolize_keys!
      end
    end
  end
end
