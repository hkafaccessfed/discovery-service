source 'https://rubygems.org'

gem 'sinatra', require: false
gem 'unicorn', require: false
gem 'god', require: false

gem 'slim'
gem 'redis'
gem 'redis-namespace'

gem 'activesupport'
gem 'hashdiff'
gem 'sinatra-contrib'

gem 'sinatra-asset-pipeline'
gem 'sprockets-helpers'

gem 'therubyracer', require: false
gem 'uglifier', require: false

source 'https://rails-assets.org' do
  gem 'rails-assets-jquery'
  gem 'rails-assets-semantic-ui'
  gem 'rails-assets-datatables'
  gem 'rails-assets-slimscroll'
end

group :development, :test do
  gem 'rspec'
  gem 'faker'
  gem 'rack-test'
  gem 'webmock'
  gem 'fakeredis'
  gem 'timecop'

  gem 'capybara', require: false
  gem 'poltergeist', require: false
  gem 'phantomjs', require: 'phantomjs/poltergeist'

  gem 'pry', require: false
  gem 'i18n', '~> 0.7.0'

  gem 'simplecov', require: false

  gem 'guard', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-rspec', require: false
  gem 'guard-bundler', require: false
  gem 'guard-unicorn', require: false
  gem 'terminal-notifier-guard', require: false

  gem 'aaf-gumboot', git: 'https://github.com/ausaccessfed/aaf-gumboot',
                     branch: 'develop'
end
