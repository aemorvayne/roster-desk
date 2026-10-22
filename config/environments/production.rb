Rails.application.configure do
  config.secret_key_base = ENV.fetch('SECRET_KEY_BASE')
  config.force_ssl = true
  config.assume_ssl = true
  config.log_level = :warn
  config.logger = ActiveSupport::Logger.new($stdout)
end
