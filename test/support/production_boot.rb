require_relative '../../config/environment'

abort 'HTTPS is required' unless Rails.application.config.force_ssl
abort 'Secure cookies are required' unless Rails.application.config.session_options[:secure]
puts 'production:secure'
