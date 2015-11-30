require 'discovery_service/persistence/entity_cache'
require 'discovery_service/cookie/store'
require 'discovery_service/response/handler'
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
    include DiscoveryService::Cookie::Store
    include DiscoveryService::Response::Handler

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

    def url?(value)
      value =~ /\A#{URI.regexp}\z/
    end

    def group_exists?(group)
      group_configured?(group) && @entity_cache.group_page_exists?(group)
    end

    def passive?(params)
      params[:isPassive] && params[:isPassive] == 'true'
    end

    get '/discovery/:group' do
      return 400 unless params[:group] =~ URL_SAFE_BASE_64_ALPHABET
      saved_user_idp = current_cookies(request)[params[:group]]
      if url?(saved_user_idp) && params[:entityID]
        params[:user_idp] = saved_user_idp
        handle_response(params)
      elsif group_exists?(params[:group])
        @entity_cache.group_page(params[:group])
      else
        status 404
      end
    end

    post '/discovery/:group' do
      return 400 unless params[:group] =~ URL_SAFE_BASE_64_ALPHABET
      return 400 if params[:user_idp] && !url?(params[:user_idp])

      if params[:remember]
        save_idp_selection(params[:group], params[:user_idp], request, response)
      end

      if passive?(params)
        handle_passive_response(params)
      else
        handle_response(params)
      end
    end
  end
end
