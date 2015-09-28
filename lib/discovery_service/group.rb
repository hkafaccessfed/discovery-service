module DiscoveryService
  module PageRenderer
    # Model for the group page
    class Group
      attr_accessor :entities

      def initialize(entities)
        @entities = entities
      end
    end
  end
end
