#!/usr/bin/env ruby

require 'bundler/setup'
Bundler.require(:default)

require_relative 'saml_service_client'

module DiscoveryService
  # Top level job to update metadata
  module UpdateMetadata
    def self.run
      DiscoveryService::SAMLServiceClient.retrieve_entity_data 'http://saml-service.example.com:443/entities'
    end
  end
end

DiscoveryService::UpdateMetadata.run
