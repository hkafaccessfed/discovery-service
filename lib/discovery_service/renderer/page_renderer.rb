require 'rails-assets-jquery'
require 'rails-assets-semantic-ui'
require 'rails-assets-datatables'
require 'rails-assets-slimscroll'
require 'sprockets'
require 'sprockets-helpers'
require 'discovery_service/application'

module DiscoveryService
  module Renderer
    # Generates a page using Slim
    module PageRenderer
      include Sprockets::Helpers

      def render(page, model)
        layout = Slim::Template.new('views/layout.slim')
        content = Slim::Template.new("views/#{page}.slim")
                  .render(model)
        layout.render(self) { content }
      end
    end
  end
end
