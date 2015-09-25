require 'yaml'
require 'redis'
require 'redis-namespace'
require 'discovery_service/entity_data_filter'
require 'discovery_service/saml_service_client'

module DiscoveryService
  # Retrieves and filters metadata from SAML service
  class MetadataUpdater
    attr_accessor :logger
    include DiscoveryService::SAMLServiceClient
    include DiscoveryService::EntityDataFilter

    def initialize
      @logger = Logger.new($stderr)
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    def update
      config = YAML.load_file('config/discovery_service.yml')
      raw_entity_data = retrieve_entity_data(config[:saml_service][:uri])
      entity_data = filter(raw_entity_data[:entities], config[:collections])
      entity_data.each do |group, entities|
        set_entity_data(group, entities)
      end
    end

    def set_entity_data(group, entities)
      key = "entities:#{group}"
      value = entities.to_json
      logger.info "Storing (k,v): ('#{key}','#{entities.to_json}')"
      @redis.set(key, value)
    end
  end
end
