require_relative '../test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def test_protects_the_directory_and_bulk_actions
    get root_path
    assert_redirected_to new_session_path
    post bulk_users_path, params: { operation: 'delete', user_ids: ['1'] }
    assert_redirected_to new_session_path
  end

  def test_registration_is_immediate_and_shows_success
    register(email: 'new@example.com', password: 'a')
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select '[role="status"]', /Your account is ready/
    assert_equal 'New Member', User.find_by!(email: 'new@example.com').full_name
  end

  def test_registration_rejects_duplicate_email
    create_user
    register(email: 'SAM@EXAMPLE.COM', password: 'a')
    assert_response :unprocessable_content
    assert_select '[role="alert"]', /Email is already registered/
    assert_equal 1, User.count
  end

  def test_registration_shows_validation_errors
    register(email: 'invalid', password: '')
    assert_response :unprocessable_content
    assert_select '[role="alert"]', /Email is invalid/
    assert_equal 0, User.count
  end

  def test_login_rejects_wrong_password_and_blocked_accounts
    user = create_user(status: 'blocked')
    submit_form(new_session_path, session_path, email: user.email, password: 'x')
    assert_response :unprocessable_content
    assert_select '[role="status"]', /account is blocked/
    assert_empty Session.all
  end

  def test_login_rotates_the_session_and_logout_revokes_it
    sign_in
    get root_path
    token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')['content']
    delete session_path, params: { authenticity_token: token }
    assert_signed_out
  end

  def test_a_blocked_session_redirects_on_the_next_request
    user = sign_in
    user.update!(status: 'blocked')
    get root_path
    assert_redirected_to new_session_path
  end

  def test_a_deleted_session_redirects_on_the_next_request
    user = sign_in
    user.delete
    get root_path
    assert_redirected_to new_session_path
  end

  def test_csrf_rejection_does_not_change_users
    user = sign_in
    post bulk_users_path, params: { operation: 'delete', user_ids: [user.id], authenticity_token: 'invalid' }
    assert_redirected_to new_session_path
    assert User.exists?(user.id)
  end

  def test_private_pages_are_not_cached
    sign_in
    get root_path
    assert_equal 'no-store', response.headers['Cache-Control']
    assert_select 'table tbody tr', count: 1
  end

  def register(**attributes)
    submit_form(new_registration_path, registration_path, user: { full_name: 'New Member', **attributes })
  end

  def assert_signed_out
    assert_redirected_to new_session_path
    assert_empty Session.all
    get root_path
    assert_redirected_to new_session_path
  end
end
