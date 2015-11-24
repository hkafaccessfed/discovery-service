require 'active_support/core_ext/hash'
require 'active_support/core_ext/object/deep_dup'

module DiscoveryService
  module Renderer
    module Helpers
      # Helpers to render group page
      module Group
        attr_accessor :tag_groups

        def can_hide?(tag_group)
          tag_group != @tag_groups.first && tag_group != @tag_groups.last
        end

        def all_tag?(tag_group)
          tag_group[:tag] == '*'
        end
      end
    end
  end
end
