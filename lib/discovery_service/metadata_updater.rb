require 'yaml'
require 'redis'
require 'redis-namespace'
require 'slim'
require 'discovery_service/entity_data_filter'
require 'discovery_service/saml_service_client'
require 'discovery_service/page_renderer'
require 'discovery_service/group'

module DiscoveryService
  # Retrieves and filters metadata from SAML service
  class MetadataUpdater
    attr_accessor :logger
    include DiscoveryService::SAMLServiceClient
    include DiscoveryService::EntityDataFilter
    include DiscoveryService::PageRenderer

    def initialize
      @logger = Logger.new($stderr)
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    def update
      config = YAML.load_file('config/discovery_service.yml')
      raw_entity_data = retrieve_entity_data(config[:saml_service][:uri])
      entity_data = filter(raw_entity_data[:entities], config[:collections])
      entity_data.each do |group, entities|
        set_entities(group, entities)
        set_page_content(group, entities)
      end
    end

    def set_page_content(group, entities)
      key = "pages:group:#{group}"
      page = render(:group, DiscoveryService::PageRenderer::Group.new(entities))
      logger.info "Storing (k,v): ('#{key}','#{page}')"
      @redis.set(key, page)
    end

    def set_entities(group, entities)
      key = "entities:#{group}"
      value = entities.to_json
      logger.info "Storing (k,v): ('#{key}','#{entities.to_json}')"
      @redis.set(key, value)
    end
  end
end
