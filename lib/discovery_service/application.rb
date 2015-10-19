require 'discovery_service/persistence/keys'
require 'discovery_service/persistence/entities'
require 'sinatra/base'
require 'json'
require 'yaml'
require 'uri'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    include DiscoveryService::Persistence::Keys
    include DiscoveryService::Persistence::Entities

    IDP_DISCOVERY_SINGLE_PROTOCOL =
        'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol:single'
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

    def sp_response_url(return_url, param_key, selected_idp)
      uri = URI.parse(return_url)
      key = param_key || :entityID
      query_opts = []
      query_opts << URI.decode_www_form(uri.query) unless uri.query.nil?
      query_opts << [key, selected_idp]
      uri.query = URI.encode_www_form(query_opts)
      uri.to_s
    end

    def entities
      build_entities(@redis.get(entities_key_for_group))
    end

    def entities_key_for_group
      entities_key(params[:group])
    end

    def discovery_response
      return nil unless @redis.exists(entities_key_for_group)
      entity_id = params[:entityID].to_sym
      return nil unless entities.key?(entity_id) &&
                        entities[entity_id].key?(:discovery_response)
      entities[entity_id][:discovery_response]
    end

    def uri?(value)
      value =~ /\A#{URI.regexp}\z/
    end

    def valid_policy?(policy)
      policy.nil? || policy == IDP_DISCOVERY_SINGLE_PROTOCOL
    end

    def valid_post_params?
      uri?(params[:entityID]) && uri?(params[:user_idp]) &&
        params[:group] =~ URL_SAFE_BASE_64_ALPHABET &&
        valid_policy?(params[:policy])
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
      return status 400 unless valid_post_params?
      return status 404 unless group_configured?(params[:group])
      if params[:isPassive] && params[:isPassive] == 'true'
        # TODO: Resolve IdP selection from cookies/storage if possible
        redirect to(params[:return])
      elsif params[:return]
        redirect to(sp_response_url(params[:return], params[:returnIDParam],
                                    params[:user_idp]))
      elsif discovery_response
        redirect to(sp_response_url(discovery_response, params[:returnIDParam],
                                    params[:user_idp]))
      else
        status 404
      end
    end
  end
end
