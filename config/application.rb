require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Onepunch
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])
    
    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    
    # Set timezone
    config.time_zone = ENV.fetch("DEFAULT_TIMEZONE", "Asia/Bangkok")
    
    # Set default URL options for development
    config.action_mailer.default_url_options = { 
      host: ENV.fetch("APP_HOST", "localhost:2030") 
    }
    
    # ActiveJob configuration - use Solid Queue
    config.active_job.queue_adapter = :solid_queue
    
    # Cache configuration - use Solid Cache
    config.cache_store = :solid_cache_store
    
    # ActiveStorage variants
    config.active_storage.variant_processor = :mini_magick
    
    # Allow Active Storage to serve images in API responses
    config.active_storage.draw_routes = true
    
    # Progressive Web App configuration
    config.pwa_enabled = true
    
    # Hotwire Native configuration
    config.hotwire_native_app = ENV.fetch("HOTWIRE_NATIVE_APP", "false") == "true"
    
    # Configure generators
    config.generators do |g|
      g.test_framework :test_unit
      g.fixture_replacement :factory_bot, dir: 'test/factories'
      g.helper false
      g.assets false
      g.jbuilder false
    end
  end
end
