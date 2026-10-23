require_relative '../test_helper'
require_relative '../support/assistant_responses'

class AccessTest < ActionDispatch::IntegrationTest
  include AssistantResponses
  def prepare_revoked_user(action)
    user = sign_in(create_user(email: "source-#{User.count}@example.com"))
    get root_path
    @token = Nokogiri::HTML(response.body).at_css('meta[name="csrf-token"]')['content']
    BulkUsers.new.call(action, [user.id])
  end

  def test_blocked_users_cannot_block_or_unblock_with_an_open_form
    %w[block unblock].each do |operation|
      prepare_revoked_user('block')
      assert_stale_operation_rejected(operation, 'Your account is blocked.')
    end
  end

  def test_deleted_users_cannot_delete_with_an_open_form
    prepare_revoked_user('delete')
    assert_stale_operation_rejected('delete', 'Your account has been deleted.')
  end

  def test_blocked_users_cannot_call_the_assistant
    prepare_revoked_user('block')
    post chat_path, params: { question: 'Count users', authenticity_token: @token }
    assert_access_message('Your account is blocked.')
    assert_not_requested :post, API_URL
  end

  def test_deleted_users_cannot_call_the_assistant
    prepare_revoked_user('delete')
    post chat_path, params: { question: 'Count users', authenticity_token: @token }
    assert_access_message('Your account has been deleted.')
    assert_not_requested :post, API_URL
  end

  def test_revoked_sessions_do_not_recover_when_the_account_is_unblocked
    prepare_revoked_user('block')
    User.update_all(status: 'active')
    get root_path
    assert_access_message('Your session has ended.')
  end

  def test_logout_checks_the_account_before_processing_the_request
    prepare_revoked_user('delete')
    delete session_path, params: { authenticity_token: @token }
    assert_access_message('Your account has been deleted.')
  end

  def test_access_check_precedes_expired_form_handling
    prepare_revoked_user('block')
    post bulk_users_path, params: { authenticity_token: 'invalid' }
    assert_access_message('Your account is blocked.')
  end

  def assert_stale_operation_rejected(operation, message)
    other = create_user(email: "target-#{operation}@example.com")
    post bulk_users_path, params: { operation: operation, user_ids: [other.id], authenticity_token: @token }
    assert_access_message(message)
    assert_equal 'active', other.reload.status
  end

  def assert_access_message(message)
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select '[role="status"]', /#{Regexp.escape(message)}/
  end
end
