require_relative 'test_helper'
require 'open3'
require 'puma'
require 'puma/configuration'

class ToolingTest < ActiveSupport::TestCase
  COVERAGE_LOADER = File.expand_path('coverage_start.rb', __dir__).freeze
  def test_runner_selects_the_pinned_ruby
    output, errors, status = Open3.capture3(RbConfig.ruby, 'bin/run.rb', 'ruby', '-e', 'puts RUBY_VERSION')
    assert status.success?, errors
    assert_equal "#{RUBY_VERSION}\n", output
  end

  def test_runner_sets_path_before_rejecting_a_missing_command
    with_environment('PATH' => ENV.fetch('PATH')) do
      assert_raises(ArgumentError) { load Rails.root.join('bin/run.rb') }
      assert_equal RbConfig::CONFIG.fetch('bindir'), ENV.fetch('PATH').split(File::PATH_SEPARATOR).first
    end
  end

  def test_rack_entry_redirects_anonymous_visitors
    app = Rack::Builder.parse_file(Rails.root.join('config.ru').to_s)
    response = Rack::MockRequest.new(app).get('/')
    assert response.redirect?
    assert_includes response.location, '/session/new'
  end

  def test_puma_uses_environment_settings
    with_environment('PORT' => '4567', 'RAILS_MAX_THREADS' => '2', 'RAILS_ENV' => 'production') do
      config = Puma::Configuration.new { |settings| settings.load(Rails.root.join('config/puma.rb').to_s) }
      config.clamp
      assert_equal([2, 2, 'production'], %i[min_threads max_threads environment].map { |key| config.options[key] })
    end
  end

  def test_rails_command_entry_point_loads_the_application
    output, errors, status = run_script('test', 'bin/rails', 'runner', 'puts Rails.application.class.name')
    assert status.success?, errors
    assert_includes output, 'RosterDesk::Application'
  end

  def test_production_boot_enforces_secure_sessions_and_https
    output, errors, status = run_script('production', 'test/support/production_boot.rb')
    assert status.success?, errors
    assert_equal "production:secure\n", output
  end

  def run_script(environment, *arguments)
    values = { 'RAILS_ENV' => environment, 'SECRET_KEY_BASE' => SecureRandom.hex(64) }
    command = [RbConfig.ruby, '-r', COVERAGE_LOADER, File.expand_path(arguments.shift), *arguments]
    Open3.capture3(values, *command)
  end
end
