require_relative 'boot'
require 'rails'
require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

Bundler.require(*Rails.groups)

module RosterDesk
  class Application < Rails::Application
    SESSION_SECRET_BYTES = 64
    config.load_defaults 8.1
    config.eager_load = Rails.env.production?
    config.secret_key_base = SecureRandom.hex(SESSION_SECRET_BYTES)
    config.cache_store = :memory_store
    config.active_record.schema_format = :sql
    config.active_record.dump_schema_after_migration = false
    config.filter_parameters += %i[password email full_name job_position question]
    config.session_store :cookie_store, key: '_roster_desk', same_site: :lax, secure: Rails.env.production?
    config.action_dispatch.default_headers['Content-Security-Policy'] =
      "default-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'self'"
  end
end
