require 'sinatra/base'
require 'lib/metadata/saml_service'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    configure :development, :test do
      enable :logging
      set :logging, Logger::DEBUG
    end

    configure :production do
      enable :logging
      set :logging, Logger::INFO
    end

    get '/' do
      slim :index
    end
  end
end
