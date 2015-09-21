#!/usr/bin/env ruby

require_relative '../init'
require 'discovery_service/metadata_updater'

DiscoveryService::MetadataUpdater.new.update
