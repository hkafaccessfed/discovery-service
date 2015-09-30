require 'sinatra/base'
require 'json'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    configure :development, :test, :production do
      enable :logging
    end

    def initialize
      super
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    get '/discovery/:group' do
      if @redis.exists("pages:group:#{params[:group]}")
        @redis.get("pages:group:#{params[:group]}")
      else
        status 404
      end
    end
  end
end
