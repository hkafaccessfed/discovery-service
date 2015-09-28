module DiscoveryService
  # Generates a page using Slim
  module PageRenderer
    def render(page, model)
      layout = Slim::Template.new('views/layout.slim')
      content = Slim::Template.new("views/#{page.to_s}.slim")
                    .render(model)
      layout.render { content }
    end
  end
end
