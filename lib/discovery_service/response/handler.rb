module DiscoveryService
  module Response
    # Module to handle user redirect / response
    module Handler
      IDP_DISCOVERY_SINGLE_PROTOCOL =
          'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol:single'
      URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/

      def handle_response(params)
        if !valid_params_for_response?(params)
          status 400
        elsif !group_configured?(params[:group])
          status 404
        else
          redirect_to_sp(params)
        end
      end

      def handle_passive_response(params)
        idp_selection = current_cookies(request)[params[:group]]
        if url?(idp_selection)
          params[:user_idp] = idp_selection
          handle_response(params)
        else
          redirect to(params[:return])
        end
      end

      private

      def redirect_to_sp(params)
        if params[:return]
          redirect_to(params[:return], params)
        elsif discovery_response(params)
          redirect_to(discovery_response(params), params)
        else
          status 404
        end
      end

      def valid_params_for_response?(params)
        url?(params[:entityID]) && url?(params[:user_idp]) &&
          params[:group] =~ URL_SAFE_BASE_64_ALPHABET &&
          valid_policy?(params[:policy])
      end

      def discovery_response(params)
        @entity_cache.discovery_response(params[:group], params[:entityID])
      end

      def redirect_to(return_url, params)
        redirect to(sp_response_url(return_url, params[:returnIDParam],
                                    params[:user_idp]))
      end

      def sp_response_url(return_url, param_key, selected_idp)
        url = URI.parse(return_url)
        key = param_key || :entityID
        query_opts = URI.decode_www_form(url.query || '') << [key, selected_idp]
        url.query = URI.encode_www_form(query_opts)
        url.to_s
      end

      def valid_policy?(policy)
        policy.nil? || policy == IDP_DISCOVERY_SINGLE_PROTOCOL
      end
    end
  end
end
