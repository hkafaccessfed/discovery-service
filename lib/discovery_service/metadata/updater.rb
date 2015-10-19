require 'yaml'
require 'redis'
require 'redis-namespace'
require 'slim'
require 'discovery_service/metadata/entity_data_filter'
require 'discovery_service/metadata/saml_service_client'
require 'discovery_service/renderer/page_renderer'
require 'discovery_service/renderer/model/group'
require 'discovery_service/persistence/entities'
require 'active_support/core_ext/numeric/time'
require 'hashdiff'

module DiscoveryService
  module Metadata
    # Retrieves and filters metadata from SAML service
    class Updater
      attr_accessor :logger
      include DiscoveryService::Metadata::SAMLServiceClient
      include DiscoveryService::Metadata::EntityDataFilter
      include DiscoveryService::Renderer::PageRenderer
      include DiscoveryService::Persistence::Entities

      def initialize
        @logger = Logger.new($stderr)
        @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
      end

      def update
        config = YAML.load_file('config/discovery_service.yml')
        raw_entities = retrieve_entity_data(config[:saml_service][:uri])
        grouped_entities = filter(raw_entities[:entities], config[:groups])
        grouped_entities.each do |group, entities|
          if !entities_exist?(group) || entities_changed?(entities, group)
            save_entities_content(group, entities)
            save_group_page_content(group, entities)
          end
          update_expiry(group)
        end
      end

      def entities_changed?(entities, group)
        entities_diff(group, entities).any?
      end

      def save_group_page_content(group, entities)
        page = render(:group,
                      DiscoveryService::Renderer::Model::Group.new(entities))
        logger.debug("Storing page for group '#{group}': '#{page}'")
        save_group_page(group, page)
      end

      def save_entities_content(group, entities)
        logger.info("Storing entities for group '#{group}': '#{entities}'")
        save_entities(entities, group)
      end
    end
  end
end
