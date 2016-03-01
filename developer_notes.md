# Developer notes

1. Run `./bin/setup` to configure your local environment.
2. Seed your local redis instance by running `bin/update_metadata.rb`.
   N.B. This will require an active
   [SAML Service](https://github.com/ausaccessfed/saml-service) instance
   which can be configured in `config/discovery_service.yml`.
3. Start the web app with `unicorn`.
