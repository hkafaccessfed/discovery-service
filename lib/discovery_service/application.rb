require 'sinatra/base'
require 'json'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/

    configure :development, :test, :production do
      enable :logging
    end

    def initialize
      super
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
    end

    get '/discovery/:group' do
      group = params[:group]
      return 400 unless group =~ URL_SAFE_BASE_64_ALPHABET

      if @redis.exists("pages:group:#{group}")
        @redis.get("pages:group:#{group}")
      else
        status 404
      end
    end
  end
end
