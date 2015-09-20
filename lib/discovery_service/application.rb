require 'sinatra/base'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    configure :development, :test do
      enable :logging
    end

    get '/' do
      slim :index
    end
  end
end
