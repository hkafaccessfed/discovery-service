require 'sinatra/base'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    get '/' do
      slim :index
    end
  end
end
