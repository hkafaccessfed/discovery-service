require 'discovery_service/entity/builder'
require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/deep_dup'

module DiscoveryService
  module Renderer
    module Controller
      # Generates group model based on requested language
      module Group
        include DiscoveryService::Entity::Builder

        def generate_group_model(entities, lang, tag_groups, environment)
          result = { idps: [], sps: [] }
          tag_set = Set.new
          entities.nil? || entities.each_with_object(result) do |e, hash|
            entity_type = entity_type_from_tags(e)
            next unless entity_type
            entry = build_entry(e, lang, entity_type)
            hash[entity_type] << entry
            tag_set.merge(entry[:tags])
          end
          build_model(environment, result, tag_groups, tag_set)
        end

        private

        def entity_type_from_tags(entity)
          return :sps if entity[:tags].include?('sp')
          return :idps if entity[:tags].include?('idp')
        end

        def build_model(environment, result, tag_groups, tag_set)
          filtered_tag_groups = filter_tag_groups(tag_groups, tag_set)
          DiscoveryService::Renderer::Model::Group.new(result[:idps],
                                                       result[:sps],
                                                       filtered_tag_groups,
                                                       environment)
        end

        def filter_tag_groups(tag_groups, tag_set)
          tag_groups.select do |tag_group|
            tag_set.include?(tag_group[:tag]) || tag_group[:tag] == '*'
          end
        end
      end
    end
  end
end
