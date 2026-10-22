require 'simplecov'

ENV['ROSTER_COVERAGE_PID'] ||= Process.pid.to_s

SimpleCov.start do
  command_name "Roster Desk #{Process.pid}"
  enable_coverage :branch, :eval
  cover 'app/**/*.rb', 'bin/*', 'config/**/*.rb', 'config.ru', 'db/migrate/*.rb', 'lib/**/*.rb', 'lib/**/*.rake',
        'Rakefile'
  cover %r{\Aapp/views/.*\.erb\z}
  cover_views
  minimum_coverage line: 100 if ENV.fetch('ROSTER_COVERAGE_PID') == Process.pid.to_s
  formatter SimpleCov::Formatter::MultiFormatter.new([]) unless ENV.fetch('ROSTER_COVERAGE_PID') == Process.pid.to_s
end
