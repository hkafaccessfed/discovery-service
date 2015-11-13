require 'rails-assets-jquery'
require 'rails-assets-semantic-ui'
require 'sprockets'
require 'sprockets-helpers'

module DiscoveryService
  module Renderer
    # Generates a page using Slim
    module PageRenderer
      include Sprockets::Helpers
      ASSET_PATH = 'lib/discovery_service/assets'
      ENVIRONMENT = Sprockets::Environment.new
      ENVIRONMENT.append_path("#{ASSET_PATH}/javascripts")
      ENVIRONMENT.append_path("#{ASSET_PATH}/stylesheets")
      RailsAssets.load_paths.each { |path| ENVIRONMENT.append_path(path) }

      Sprockets::Helpers.configure do |config|
        config.environment = ENVIRONMENT
        config.digest      = true
      end

      def render(page, model)
        layout = Slim::Template.new('views/layout.slim')
        content = Slim::Template.new("views/#{page}.slim")
                  .render(model)
        layout.render(self) { content }
      end
    end
  end
end
