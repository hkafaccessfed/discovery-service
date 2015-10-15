require 'discovery_service/persistence/keys'
require 'discovery_service/persistence/entities'
require 'sinatra/base'
require 'json'
require 'yaml'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    include DiscoveryService::Persistence::Keys
    include DiscoveryService::Persistence::Entities

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

    def group_configured?(group)
      @groups.key?(group.to_sym)
    end

    def entities
      entities_as_string = @redis.get(entities_key(params[:group]))
      build_entities(entities_as_string)
    end

    def sp_url_with_entity_id(path)
      url = path.include?('?') ? "#{path}&" : "#{path}?"
      url_params = Rack::Utils.build_query(entityID: params[:user_idp])
      "#{url}#{url_params}"
    end

    def entity_exists?
      @redis.exists(entities_key(params[:group])) &&
        entities.key?(params[:entity_id].to_sym)
    end

    get '/discovery/:group' do
      group = params[:group]
      return 400 unless group =~ URL_SAFE_BASE_64_ALPHABET
      if group_configured?(group) && @redis.exists(group_page_key(group))
        @redis.get(group_page_key(group))
      else
        status 404
      end
    end

    post '/discovery/:group' do
      params.symbolize_keys! # Verify these param are safe
      return status 404 unless group_configured?(params[:group])
      if params.key?(:return)
        redirect to(sp_url_with_entity_id(params[:return]))
      elsif entity_exists?
        sp_url = entities[params[:entity_id].to_sym][:discovery_response]
        redirect to(sp_url_with_entity_id(sp_url))
      else
        status 404
      end
    end
  end
end
