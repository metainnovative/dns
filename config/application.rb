require_relative 'boot'

require 'rails'
require 'active_model/railtie'
require 'active_job/railtie'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_cable/engine'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

module Ads
  class Application < Rails::Application
    config.load_defaults 6.1
    config.time_zone = 'Paris'
    config.api_only = true
  end
end
