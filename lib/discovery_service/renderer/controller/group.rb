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
            entity_type = entity_type_from_tags(e)
            hash[entity_type] << entry(e, lang, entity_type) if entity_type
          end
          DiscoveryService::Renderer::Model::Group.new(result[:idps],
                                                       result[:sps],
                                                       tag_groups,
                                                       environment)
        end

        private

        def entity_type_from_tags(entity)
          return :sps if entity[:tags].include?('sp')
          return :idps if entity[:tags].include?('idp')
        end

        def entry(entity, lang, entity_type)
          entry = base_entry(entity, lang)
          if entity_type == :sps
            set_information_url(entity, entry, lang)
            set_privacy_statement_url(entity, entry, lang)
          elsif entity_type == :idps
            entry[:geolocations] = entity[:geolocations]
          end
          entry
        end

        def base_entry(entity, lang)
          entry = {}
          entry[:entity_id] = entity[:entity_id]
          entry[:tags] = entity[:tags]
          set_name(entity, entry, lang)
          set_logo(entity, entry, lang)
          set_description(entity, entry, lang)
          entry
        end

        def set_description(entity, entry, lang)
          description = value(:descriptions, :value, entity, lang)
          entry[:description] = description if description
        end

        def set_logo(entity, entry, lang)
          logo_url = value(:logos, :url, entity, lang)
          entry[:logo_url] = logo_url if logo_url
        end

        def set_name(entity, entry, lang)
          name = value(:names, :value, entity, lang)
          entry[:name] = name.nil? ? entity[:entity_id] : name
        end

        def set_privacy_statement_url(entity, entry, lang)
          privacy_statement_url = value(:privacy_statement_urls, :url,
                                        entity, lang)
          entry[:privacy_statement_url] =
              privacy_statement_url if privacy_statement_url
        end

        def set_information_url(entity, entry, lang)
          information_url = value(:information_urls, :url, entity, lang)
          entry[:information_url] = information_url if information_url
        end

        def value(field, key, entity, lang)
          return nil unless entity[field]
          values = entity[field].select { |value| value[:lang] == lang }
          values.first[key] if values.any?
        end
      end
    end
  end
end
