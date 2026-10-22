ENV['RAILS_ENV'] = 'test'

require_relative 'coverage_start'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
require 'webmock/minitest'

WebMock.disable_net_connect!(allow_localhost: true)
ActiveModel::SecurePassword.min_cost = true
ActiveRecord::Migration.verbose = false
ActiveRecord::Base.connection.drop_table(:sessions, if_exists: true)
ActiveRecord::Base.connection.drop_table(:users, if_exists: true)
ActiveRecord::Base.connection.drop_table(:schema_migrations, if_exists: true)
ActiveRecord::MigrationContext.new(Rails.root.join('db/migrate')).migrate

module TestData
  def setup
    super
    User.delete_all
    Rails.cache.clear
  end

  def create_user(**attributes)
    User.create!(full_name: 'Sam Rowan', email: 'sam@example.com', password: 'x', **attributes)
  end

  def with_environment(values)
    original = values.keys.to_h { |key| [key, ENV.fetch(key, nil)] }
    ENV.update(values)
    yield
  ensure
    ENV.update(original)
  end
end

class ActiveSupport::TestCase
  include TestData
  self.use_transactional_tests = false
end

class ActionDispatch::IntegrationTest
  def submit_form(path, target, parameters)
    get path
    token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')['content']
    post target, params: parameters.merge(authenticity_token: token)
  end

  def sign_in(user = create_user)
    submit_form(new_session_path, session_path, email: user.email, password: 'x')
    assert_redirected_to root_path
    user
  end

  def bulk_action(operation, ids)
    submit_form(root_path, bulk_users_path, operation: operation, user_ids: ids)
  end
end
