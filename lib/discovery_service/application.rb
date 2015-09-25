require 'sinatra/base'
require 'json'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    configure :development, :test do
      enable :logging
    end

    def initialize
      super
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    get '/discovery/:group' do
      entity_data = @redis.get("entities:#{params[:group]}")
      return status 404 unless entity_data
      @entity_data = JSON.parse(entity_data) if entity_data
      slim :index
    end
  end
end
