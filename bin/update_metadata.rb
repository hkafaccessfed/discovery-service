#!/usr/bin/env ruby

require_relative '../init'
require 'yaml'
require 'lib/saml_service_client'
require 'lib/entity_data_filter'

config = YAML.load_file('config/discovery_service.yml')
entity_data = DiscoveryService::SAMLServiceClient.retrieve_entity_data( \
  config[:saml_service][:uri])
filtered_entity_data = DiscoveryService::EntityDataFilter.filter(
  entity_data[:entities], config[:collections])

puts "\nNOW CACHE THIS: #{JSON.pretty_generate(filtered_entity_data)}"
