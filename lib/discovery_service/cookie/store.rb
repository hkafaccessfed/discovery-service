require 'json'

module DiscoveryService
  module Cookie
    # Module to handle storage / retrieval of cookies
    module Store
      SELECTED_ORGANISATIONS_KEY = 'selected_organisations'
      RECENT_ORGANISATIONS_KEY = 'recent_organisations'

      def save_idp_selection(group, user_idp, request, response)
        cookies = cookie(request, SELECTED_ORGANISATIONS_KEY)
        cookies[group] = user_idp
        save_cookie(response, SELECTED_ORGANISATIONS_KEY, cookies)
      end

      def save_recent_idp_selection(group, user_idp, request, response)
        cookies = cookie(request, RECENT_ORGANISATIONS_KEY)
        cookies[group] = [] unless cookies.key?(group)
        cookies[group] << user_idp
        cookies[group] = cookies[group].last(3)
        save_cookie(response, RECENT_ORGANISATIONS_KEY, cookies)
      end

      def delete_idp_selection(response)
        response.delete_cookie(SELECTED_ORGANISATIONS_KEY)
      end

      def idp_selections(request)
        cookie(request, SELECTED_ORGANISATIONS_KEY)
      end

      private

      def cookie(request, cookie_key)
        if request.cookies.include?(cookie_key)
          JSON.parse(request.cookies[cookie_key])
        else
          {}
        end
      end

      def save_cookie(response, key, cookies_as_hash)
        json_generate = JSON.generate(cookies_as_hash)
        response.set_cookie(key,
                            value: json_generate,
                            path: '/',
                            expires: Time.now + 3.months)
      end
    end
  end
end
