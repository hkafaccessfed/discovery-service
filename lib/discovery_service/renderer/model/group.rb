module DiscoveryService
  module Renderer
    module Model
      # Model for the group page
      class Group
        attr_accessor :entities

        def initialize(entities)
          @entities = entities
        end
      end
    end
  end
end
