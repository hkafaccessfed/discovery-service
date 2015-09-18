module DiscoveryService
  # Filters entity data based on tag config
  module EntityDataFilter
    def filter(entity_data, tag_config)
      results = {}
      tag_config.each do |group, tags|
        tags.each do |tag|
          entity_data.each do |entity|
            add_entity_if_tags_match(entity, group, results, tag)
          end
        end
      end
      results
    end

    def add_entity_if_tags_match(entity, group, results, tag)
      if entity[:tags].to_set.superset?(tag.to_set)
        results[group] = [] unless results.key?(group)
        results[group].push(entity)
      end
    end
  end
end
