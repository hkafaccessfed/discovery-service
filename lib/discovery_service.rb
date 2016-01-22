require 'yaml'

require 'discovery_service/persistence/entity_cache'
require 'discovery_service/cookie/store'
require 'discovery_service/response/handler'
require 'discovery_service/response/api_response_builder'
require 'discovery_service/entity/builder'
require 'discovery_service/validation/request_validations'
require 'discovery_service/auditing'
require 'discovery_service/embedded_wayf'
require 'discovery_service/application'

# Top-level module for the Discovery Service project.
module DiscoveryService
  CONFIG_FILE = 'config/discovery_service.yml'

  class <<self
    attr_reader :configuration
  end

  @configuration = YAML.load_file(CONFIG_FILE)
end
