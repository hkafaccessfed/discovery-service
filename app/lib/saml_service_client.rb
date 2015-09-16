require 'logger'

module DiscoveryService
  # For interaction with SAML Service
  module SAMLServiceClient
    @logger = Logger.new($stderr)

    def self.retrieve_entity_data(saml_service_uri)
      uri = URI.parse(saml_service_uri)
      req = Net::HTTP::Get.new(uri)
      with_saml_service_client(uri) do |http|
        response = http.request(req)
        response.value # Raise exception on HTTP error
        parse_response(response)
      end
    rescue Net::HTTPServerException => e
      log_error(e, saml_service_uri)
      raise e
    end

    def self.parse_response(response)
      @logger.info "Parsing response (#{response.body})"
      JSON.parse(response.body, symbolize_names: true)
    end

    def self.with_saml_service_client(uri)
      client = Net::HTTP.new(uri.host, uri.port)
      @logger.info "Invoking SAML Service (#{uri})"
      client.start { |http| yield http }
    end

    def self.log_error(e, saml_service_uri)
      @logger.error "SAMLService HTTPServerException #{e.message} while" \
          " invoking #{saml_service_uri}"
    end
  end
end
