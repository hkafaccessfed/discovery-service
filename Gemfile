source 'https://rubygems.org'

gem 'sinatra', require: false
gem 'unicorn', require: false

gem 'slim'

group :development, :test do
  gem 'rspec'
  gem 'faker'
  gem 'rack-test'
  gem 'webmock'

  gem 'capybara', require: false
  gem 'poltergeist', require: false
  gem 'phantomjs', require: 'phantomjs/poltergeist'

  gem 'pry', require: false

  gem 'simplecov', require: false

  gem 'guard', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-rspec', require: false
  gem 'guard-bundler', require: false
  gem 'guard-unicorn', require: false
  gem 'terminal-notifier-guard', require: false

  gem 'aaf-gumboot', git: 'https://github.com/ausaccessfed/aaf-gumboot',
                     branch: 'develop'
  # Have to drag in this dependency for gumboot
  gem 'activesupport', require: false
end
