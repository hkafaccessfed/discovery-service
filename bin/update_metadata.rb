#!/usr/bin/env ruby

require_relative '../init'
Bundler.require(:default) # Move to init?

require 'lib/saml_service_client'
require 'yaml'

config = YAML.load_file('config/discovery_service.yml')
DiscoveryService::SAMLServiceClient.retrieve_entity_data \
  config[:saml_service][:uri]
