thread_count = Integer(ENV.fetch('RAILS_MAX_THREADS', '5'))
threads thread_count, thread_count
port ENV.fetch('PORT', '3000')
environment ENV.fetch('RAILS_ENV', 'development')
