module DiscoveryService
  module Renderer
    module Model
      # Model for the group page
      class Group
        attr_accessor :idps
        attr_accessor :sps

        def initialize(idps, sps)
          @idps = idps
          @sps = sps
        end
      end
    end
  end
end
