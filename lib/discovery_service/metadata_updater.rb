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
    end

    def update(redis)
      config = YAML.load_file('config/discovery_service.yml')
      raw_entity_data = retrieve_entity_data(config[:saml_service][:uri])
      entity_data = filter(raw_entity_data[:entities], config[:collections])
      redis.set('entity_data', entity_data.to_json)
    end
  end
end
