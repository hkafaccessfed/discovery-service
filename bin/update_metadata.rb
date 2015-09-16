#!/usr/bin/env ruby

require_relative '../init'
Bundler.require(:default) # Move to init?

require 'lib/saml_service_client'

module DiscoveryService
  # Top level job to update metadata
  module UpdateMetadata
    def self.run
      DiscoveryService::SAMLServiceClient.retrieve_entity_data 'http://localhost:8080/entities'
    end
  end
end

DiscoveryService::UpdateMetadata.run
