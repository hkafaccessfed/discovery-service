require 'json'

module DiscoveryService
  module Cookie
    # Module to handle storage / retrieval of cookies
    module Store
      SELECTED_ORGANISATIONS_KEY = 'selected_organisations'

      def save_idp_selection(group, user_idp, request, response)
        cookies = idp_selections(request)
        cookies[group] = user_idp
        response.set_cookie(SELECTED_ORGANISATIONS_KEY,
                            value: JSON.generate(cookies),
                            expires: Time.now + 3.months)
      end

      def idp_selections(request)
        if request.cookies.include?(SELECTED_ORGANISATIONS_KEY)
          cookies_to_json(request.cookies[SELECTED_ORGANISATIONS_KEY])
        else
          {}
        end
      end

      private

      def cookies_to_json(cookies_as_string)
        JSON.parse(cookies_as_string)
      end
    end
  end
end
