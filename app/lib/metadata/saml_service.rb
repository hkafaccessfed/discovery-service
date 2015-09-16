module Metadata
  # Provides integration for SAML Service.
  module SAMLService
    def idp_sp_data(saml_service_uri)
      uri = URI.parse(saml_service_uri)
      req = Net::HTTP::Get.new(uri)

      with_saml_service_client(uri) do |http|
        response = http.request(req)
        response.value # Raise exception on HTTP error
        JSON.parse(response.body, symbolize_names: true)
      end
    rescue Net::HTTPServerException => e
      logger.error "SAMLService HTTPServerException #{e.message} while" \
        " invoking #{saml_service_uri}"
      raise e
    end

    def with_saml_service_client(uri)
      client = Net::HTTP.new(uri.host, uri.port)
      client.start { |http| yield http }
    end
  end
end
