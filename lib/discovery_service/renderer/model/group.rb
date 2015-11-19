module DiscoveryService
  module Renderer
    module Model
      # Model for the group page
      class Group
        attr_accessor :idps
        attr_accessor :sps
        attr_accessor :environment

        def initialize(idps, sps, environment)
          @idps = idps
          @sps = sps
          @environment = environment
        end
      end
    end
  end
end
