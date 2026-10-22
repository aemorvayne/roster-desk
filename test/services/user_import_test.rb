require_relative '../test_helper'
require 'tempfile'
require 'open3'

class UserImportTest < ActiveSupport::TestCase
  def test_imports_fields_and_uses_independent_random_passwords
    import([contact, contact(email: 'pat@example.org')])
    assert_equal 2, User.count
    assert_equal 2, User.distinct.count(:password_digest)
    assert_equal ['Editor', 'blocked', Time.utc(2026, 1, 1)],
                 User.first.values_at(:job_position, :status, :last_login_at)
  end

  def test_rolls_back_the_entire_import_on_duplicate_emails
    assert_raises(UserImport::Error) { import([contact, contact(email: 'SAM@EXAMPLE.COM')]) }
    assert_empty User.all
  end

  def test_rejects_missing_dates_bad_timestamps_and_invalid_status
    assert_raises(UserImport::Error) { import([contact.except('last_seen')]) }
    assert_raises(UserImport::Error) { import([contact(last_seen: 'invalid')]) }
    assert_raises(UserImport::Error) { import([contact(status: 'unknown')]) }
    assert_empty User.all
  end

  def test_preserves_existing_accounts
    user = create_user
    assert_raises(UserImport::Error) { import([contact]) }
    assert_equal [user.id], User.ids
  end

  def test_rejects_malformed_json_and_wrong_record_shapes
    assert_raises(UserImport::Error) { UserImport.new.call(StringIO.new('invalid')) }
    assert_raises(UserImport::Error) { import({}) }
    assert_raises(UserImport::Error) { import(['invalid']) }
  end

  def test_does_not_read_contacts_from_inside_the_application
    path = Rails.root.join('Gemfile').to_s
    assert_raises(UserImport::Error) { UserImport.from_file(path) }
    assert_empty User.all
  end

  def test_import_command_reads_an_external_file_and_reports_only_the_count
    with_contact_file { |path| assert_import_success(path) }
    assert_equal ['sam@example.com'], User.pluck(:email)
  end

  def assert_import_success(path)
    output, errors, status = run_import(path)
    assert status.success?, errors
    assert_equal "1 user(s) imported.\n", output
  end

  def contact(**values)
    { 'full_name' => 'Sam Rowan', 'email' => 'sam@example.com', 'job_position' => 'Editor',
      'status' => 'blocked', 'last_seen' => '2026-01-01T00:00:00Z' }.merge(values.stringify_keys)
  end

  def import(records)
    UserImport.new.call(StringIO.new(records.to_json))
  end

  def with_contact_file
    Tempfile.create(['contacts', '.json']) do |file|
      file.write([contact].to_json)
      file.flush
      yield file.path
    end
  end

  def run_import(path)
    command = [RbConfig.ruby, '-r', Rails.root.join('test/coverage_start.rb').to_s, '-S', 'rake', 'import']
    Open3.capture3({ 'CONTACTS_PATH' => path }, *command)
  end
end
