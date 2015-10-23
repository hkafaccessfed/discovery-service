module DiscoveryService
  module Renderer
    module Controller
      # Generates group model based on requested language
      module Group
        def generate_group_model(entities, lang)
          model = []
          if entities
            model = entities.map do |e|
              names = e[:names].select { |n| n[:lang] == lang }
              { name: names.any? ? names.first[:value] : e[:entity_id],
                entity_id: e[:entity_id] }
            end
          end
          DiscoveryService::Renderer::Model::Group.new(model)
        end
      end
    end
  end
end
