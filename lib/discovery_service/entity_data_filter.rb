module DiscoveryService
  # Filters entity data based on tag config
  module EntityDataFilter
    def filter(entity_data, tag_config)
      tag_config.reduce({}) do |hash, (group, tags)|
        entities = entity_data.select { |entity| contains_tag(entity, tags) }
        hash.merge(group => entities)
      end
    end

    def contains_tag(entity, tags)
      tags.each do |tag|
        return true if entity[:tags].to_set.superset?(tag.to_set)
      end
      false
    end
  end
end
