require 'sinatra/base'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    configure do
      enable :logging
      file = File.new("log/#{settings.environment}.log", 'a')
      file.sync = true
      use Rack::CommonLogger, file
    end

    get '/' do
      slim :index
    end
  end
end
