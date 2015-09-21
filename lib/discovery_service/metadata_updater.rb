require 'yaml'
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

    def update
      config = YAML.load_file('config/discovery_service.yml')
      entity_data = retrieve_entity_data(config[:saml_service][:uri])
      filter(entity_data[:entities], config[:collections])
    end
  end
end
