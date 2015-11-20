require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/deep_dup'

module DiscoveryService
  module Renderer
    module Controller
      # Generates group model based on requested language
      module Group
        def generate_group_model(entities, lang, tag_groups, environment)
          result = { idps: [], sps: [] }
          entities.nil? || entities.each_with_object(result) do |e, hash|
            hash[group(e)] << entry(e, lang) if group(e)
          end
          DiscoveryService::Renderer::Model::Group.new(result[:idps],
                                                       result[:sps],
                                                       tag_groups,
                                                       environment)
        end

        private

        def group(entity)
          return :sps if entity[:tags].include?('sp')
          return :idps if entity[:tags].include?('idp')
        end

        def names_for_language(entity, lang)
          return [] unless entity[:names]
          entity[:names].select { |name| name[:lang] == lang }
        end

        def entry(entity, lang)
          names = names_for_language(entity, lang)
          entry = entity.deep_dup.except(:names)
          entry[:name] = names.any? ? names.first[:value] : entity[:entity_id]
          entry
        end
      end
    end
  end
end
