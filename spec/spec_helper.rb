
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"

# We provide an empty google maps api key for the tests to complete successfully.
# We largely set this here so that tests from travisCI won't fail with this
# variable missing.
ENV["GOOGLE_MAPS_API_KEY"] = "test-key"
require "simplecov"
require "coveralls"
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
])
SimpleCov.start do
  add_filter "config/initializers/rack-attack.rb"
  add_filter "config/environment.rb"
  add_filter "config/initializers/mongoid.rb"
  add_filter "config/initializers/backtrace_silencers.rb"
  add_filter "spec/"
end
require File.expand_path("../../config/environment", __FILE__)
# SEE: https://github.com/rails/rails/issues/18572
require "test/unit/assertions"
# =====
require "rspec/rails"
require "capybara/rails"
require "webmock/rspec"
require "vcr"
require "webmock/rspec"
require "pundit/rspec"

# ====== PHANTOMJS stuff
begin
  open("http://search:9200") # Funny hack
rescue Errno::ECONNREFUSED => x
  sleep 0.3
  puts "Wiating for ElasticSearch to start..."
end

# ?===
Capybara.javascript_driver = :selenium
Capybara.app_host = "http://web"
Capybara.server_port = 3000
Capybara.run_server = true
# I don't think Puma's speed is worth adding a
# new test dependency.
Capybara.server = :webrick

# Configure the Chrome driver capabilities & register
args = ["--no-default-browser-check", "--start-maximized"]
caps = Selenium::WebDriver::Remote::Capabilities.firefox
Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app,
                                 browser: :remote,
                                 url: "http://hub:4444/wd/hub",
                                 desired_capabilities: caps)
end
# ?===

Delayed::Worker.delay_jobs = false
# ===== VCR stuff (records HTTP requests for playback)
VCR.configure do |c|
  c.cassette_library_dir = "vcr"
  c.hook_into :webmock # or :fakeweb
  c.default_cassette_options = {
    record: :new_episodes,
    match_requests_on: [:host, :method],
  }
  c.ignore_localhost = true
  c.ignore_request do |request|
    [
      9200, # Elastic search
      4444, # Selenium hub
    ].include? URI(request.uri).port
  end
end
# =====

Paperclip.options[:log] = false

require "database_cleaner"
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Mongoid.logger.level = 2
Guide.reindex
Crop.reindex
RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.include Rails.application.routes.url_helpers
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ApiHelpers, type: :controller
  config.include IntegrationHelper, type: :feature
  config.include Capybara::DSL
  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.fail_fast = false
  config.order = "random"
  if ENV["DOCS"] == "true"
    SmarfDoc.config do |c|
      c.template_file = "spec/template.md.erb"
      c.output_file = "api_docs.md"
    end

    config.after(:each, type: :controller) do
      SmarfDoc.run!(request, response) if request.url.include?("/api/")
    end

    config.after(:suite) { SmarfDoc.finish! }
  end
  config.before :each do
    # This speed _everything_ up:
    User.collection.drop
    Crop.collection.drop
    Guide.collection.drop
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers
end

class Legacy # Don't write new code that uses this
  extend Rails::Controller::Testing::Integration

  def self._get(this, action, params = {})
    this.get action, params: params
  end

  def self._patch(this, action, params = {})
    this.patch action, params: params
  end

  def self._delete(this, action, params = {})
    this.delete action, params: params
  end

  def self._put(this, action, params = {})
    this.put action, params: params
  end

  def self._post(this, action, params = {})
    this.post action, params: params
  end
end
