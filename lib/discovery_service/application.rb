require 'sinatra/base'
require 'json'
require 'yaml'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/

    TEST_CONFIG = 'spec/feature/config/discovery_service.yml'
    CONFIG = 'config/discovery_service.yml'

    set :group_config, CONFIG

    configure :test do
      set :group_config, TEST_CONFIG
    end

    def initialize
      super
      @logger = Logger.new("log/#{settings.environment}.log")
      @redis = Redis::Namespace.new(:discovery_service, redis: Redis.new)
      @groups = YAML.load_file(settings.group_config)[:groups]
      @logger.info('Initialised with group configuration: '\
        "#{JSON.pretty_generate(@groups)}")
    end

    get '/discovery/:group' do
      group = params[:group]
      return 400 unless group =~ URL_SAFE_BASE_64_ALPHABET
      key = "pages:group:#{group}"
      if @groups.key?(group.to_sym) && @redis.exists(key)
        @redis.get(key)
      else
        status 404
      end
    end
  end
end
