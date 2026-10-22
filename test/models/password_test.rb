require_relative '../test_helper'

class PasswordTest < ActiveSupport::TestCase
  LONG_PASSWORD = '🧭' * 128
  def test_preserves_long_passwords_without_truncating_them
    user = create_user(password: LONG_PASSWORD)
    assert_equal user, user.authenticate(LONG_PASSWORD)
    refute user.authenticate(LONG_PASSWORD.chop)
    assert_match(/\A\$argon2id\$/, user.password_digest)
  end

  def test_accepts_a_space_as_a_non_empty_password
    user = create_user(password: ' ')
    assert_equal user, user.authenticate(' ')
    refute user.authenticate('')
  end

  def test_rejects_empty_or_missing_passwords_without_creating_a_digest
    [nil, ''].each { |value| assert_empty_password(value) }
    refute User.new.authenticate('x')
  end

  def assert_empty_password(value)
    user = User.new(full_name: 'Pat River', email: 'pat@example.com', password: value)
    refute user.valid?
    assert_nil user.password_digest
    assert_includes user.errors[:password], "can't be empty"
  end
end
