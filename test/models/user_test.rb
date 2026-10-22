require_relative '../test_helper'

class UserTest < ActiveSupport::TestCase
  def test_normalizes_names_and_authenticates_a_one_character_password
    user = create_user(full_name: ' Sam Rowan ', email: ' SAM@EXAMPLE.COM ', job_position: ' Editor ')
    assert_equal ['Sam Rowan', 'sam@example.com', 'Editor'], user.values_at(:full_name, :email, :job_position)
    assert_equal user, User.authenticate_by(email: ' SAM@EXAMPLE.COM ', password: 'x')
    refute user.authenticate('wrong')
  end

  def test_requires_name_email_and_password
    user = User.new(full_name: ' ', email: 'invalid', password: '')
    refute user.valid?
    assert_equal %i[email full_name password], user.errors.attribute_names.sort
  end

  def test_rejects_invalid_status_and_oversized_fields
    user = create_user
    user.assign_attributes(status: 'unknown', job_position: 'a' * User::FIELD_LIMIT.next)
    refute user.valid?
    assert_equal %i[job_position status], user.errors.attribute_names.sort
  end

  def test_unique_index_rejects_duplicates_without_model_validation
    user = create_user
    attributes = user.attributes.except('id').merge('email' => user.email.upcase)
    assert_raises(ActiveRecord::RecordNotUnique) { User.insert_all!([attributes]) }
    assert_equal 1, User.count
  end

  def test_database_rejects_invalid_status_and_missing_fields
    user = create_user
    assert_raises(ActiveRecord::StatementInvalid) { user.update_column(:status, 'unknown') }
    assert_raises(ActiveRecord::NotNullViolation) { user.update_column(:email, nil) }
  end

  def test_sessions_record_last_login_and_are_deleted_with_the_user
    user = create_user
    login = Session.start(user)
    assert_in_delta Time.current.to_f, user.reload.last_login_at.to_f, 1
    user.delete
    refute Session.exists?(login.id)
  end

  def test_unique_index_is_an_expression_index_separate_from_primary_key
    index = User.connection.indexes(:users).find { |item| item.name == 'users_email_unique' }
    assert index.unique
    assert_includes index.columns, 'lower'
    assert_equal 'id', User.primary_key
  end
end
