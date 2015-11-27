require 'discovery_service/renderer/helpers/group'

module DiscoveryService
  module Renderer
    module Model
      # Model for the group page
      class Group
        attr_accessor :idps
        attr_accessor :sps
        attr_accessor :tag_groups
        attr_accessor :environment

        include DiscoveryService::Renderer::Helpers::Group

        def initialize(idps, sps, tag_groups, environment)
          @idps = idps
          @sps = sps
          @tag_groups = tag_groups
          @environment = environment
        end
      end
    end
  end
end
