module DiscoveryService
  module Validation
    # Module to handle request validation
    module RequestValidations
      URL_SAFE_BASE_64_ALPHABET = /^[a-zA-Z0-9_-]+$/
      IDP_DISCOVERY_SINGLE_PROTOCOL =
          'urn:oasis:names:tc:SAML:profiles:SSO:idp-discovery-protocol:single'

      def url?(value)
        !value.nil? && value =~ /\A#{URI.regexp}\z/
      end

      def passive?(params)
        params[:isPassive] && params[:isPassive] == 'true'
      end

      def valid_group_name?(group)
        group =~ URL_SAFE_BASE_64_ALPHABET
      end

      def valid_policy?(policy)
        policy.nil? || policy == IDP_DISCOVERY_SINGLE_PROTOCOL
      end

      def valid_params?
        valid_group_name?(params[:group]) &&
          (passive?(params) || url?(params[:user_idp])) &&
          url?(params[:entityID]) &&
          valid_policy?(params[:policy])
      end
    end
  end
end
