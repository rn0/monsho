source 'http://rubygems.org'

gem "rails", "3.1.0.beta1"
gem "eventmachine", "1.0.0.beta3"
gem "thin"
gem "mongoid",   :git => "git://github.com/mongoid/mongoid.git"
gem "bson_ext", "~>1.3"
gem "devise"
gem "mongoid-tree", :require => "mongoid/tree"
gem "nokogiri"
gem "kaminari"
gem "jquery-rails"
gem "sass"
#gem "mongo-rails-instrumentation"
gem "slim"
gem "rsolr"
gem "babosa"

group :development do
  gem "slim-rails"
end
group :test, :development do
  gem 'rspec-rails', '~>2.6.0.rc'
end
group :test do
  #gem 'database_cleaner'
  #gem 'factory_girl_rails'
  #gem 'mongoid-rspec'
  gem 'spork', '~> 0.9.0.rc'
  gem 'valid_attribute'
end