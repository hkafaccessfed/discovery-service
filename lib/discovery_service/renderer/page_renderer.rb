module DiscoveryService
  module Renderer
    # Generates a page using Slim
    module PageRenderer
      def render(page, model)
        layout = Slim::Template.new('views/layout.slim')
        content = Slim::Template.new("views/#{page}.slim")
                  .render(model)
        layout.render { content }
      end
    end
  end
end
