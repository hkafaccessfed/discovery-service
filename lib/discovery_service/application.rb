require 'discovery_service/persistence/entity_cache'
require 'sinatra/base'
require 'sinatra/cookies'
require 'sinatra/asset_pipeline'
require 'rails-assets-jquery'
require 'rails-assets-semantic-ui'
require 'rails-assets-datatables'
require 'rails-assets-slimscroll'
require 'sprockets'
require 'sprockets-helpers'
require 'json'
require 'yaml'
require 'uri'

module DiscoveryService
  # Web application to allow users to select their IdP
  class Application < Sinatra::Base
    IDP_DISCOVERY_SINGLE_PROTOCOL =
        'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol:single'
    URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/

    TEST_CONFIG = 'spec/feature/config/discovery_service.yml'
    CONFIG = 'config/discovery_service.yml'

    set :assets_precompile,
        %w(application.js application.css *.eot *.woff *.woff2 *.ttf)
    set :assets_css_compressor, :sass
    set :assets_js_compressor, :uglifier

    register Sinatra::AssetPipeline

    RailsAssets.load_paths.each { |path| settings.sprockets.append_path(path) }
    settings.sprockets.append_path('assets/javascripts')
    settings.sprockets.append_path('assets/stylesheets')

    helpers Sprockets::Helpers

    set :group_config, CONFIG
    set :public_folder, 'public'

    configure :test do
      set :group_config, TEST_CONFIG
    end

    def initialize
      super
      @logger = Logger.new("log/#{settings.environment}.log")
      @entity_cache = DiscoveryService::Persistence::EntityCache.new
      @groups = YAML.load_file(settings.group_config)[:groups]
      @logger.info('Initialised with group configuration: '\
        "#{JSON.pretty_generate(@groups)}")
    end

    def group_configured?(group)
      @groups.key?(group.to_sym)
    end

    def sp_response_url(return_url, param_key, selected_idp)
      url = URI.parse(return_url)
      key = param_key || :entityID
      query_opts = URI.decode_www_form(url.query || '') << [key, selected_idp]
      url.query = URI.encode_www_form(query_opts)
      url.to_s
    end

    def url?(value)
      value =~ /\A#{URI.regexp}\z/
    end

    def valid_policy?(policy)
      policy.nil? || policy == IDP_DISCOVERY_SINGLE_PROTOCOL
    end

    def valid_post_params?
      url?(params[:entityID]) && url?(params[:user_idp]) &&
        params[:group] =~ URL_SAFE_BASE_64_ALPHABET &&
        valid_policy?(params[:policy])
    end

    get '/discovery/:group' do
      group = params[:group]
      return 400 unless group =~ URL_SAFE_BASE_64_ALPHABET
      if group_configured?(group) && @entity_cache.group_page_exists?(group)
        @entity_cache.group_page(group)
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
      elsif @entity_cache.discovery_response(params[:group], params[:entityID])
        redirect to(sp_response_url(@entity_cache.discovery_response(
                                      params[:group], params[:entityID]),
                                    params[:returnIDParam],
                                    params[:user_idp]))
      else
        status 404
      end
    end
  end
end
