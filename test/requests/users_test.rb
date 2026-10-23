require_relative '../test_helper'

class UsersTest < ActionDispatch::IntegrationTest
  def test_blocks_and_unblocks_another_user_and_revokes_their_sessions
    sign_in
    other = create_user(email: 'pat@example.com')
    Session.start(other)
    assert_bulk_status(other, 'block', 'blocked')
    assert_bulk_status(other, 'unblock', 'active')
  end

  def test_self_block_redirects_to_sign_in
    user = sign_in
    bulk_action('block', [user.id])
    assert_redirected_to new_session_path
    assert_equal 'blocked', user.reload.status
  end

  def test_self_deletion_removes_the_account_and_allows_registration_again
    user = sign_in
    bulk_action('delete', [user.id])
    assert_redirected_to new_session_path
    assert_empty User.all
    assert create_user.persisted?
  end

  def test_invalid_action_and_empty_selection_are_reported
    user = sign_in
    assert_bulk_error('unknown', [user.id], 'Choose a valid action.')
    assert_bulk_error('delete', [], 'Select at least one existing user.')
    assert User.exists?(user.id)
  end

  def test_table_has_checkboxes_toolbar_and_no_row_buttons
    sign_in
    create_user(email: 'pat@example.com')
    get root_path
    assert_table_structure
    assert_select 'tbody', /Never signed in/
  end

  def test_malformed_identifiers_cannot_delete_real_users
    user = sign_in
    assert_bulk_error('delete', ["#{user.id}garbage"], 'Select users using the checkboxes.')
    assert_bulk_error('delete', { 'id' => user.id }, 'Select users using the checkboxes.')
    assert User.exists?(user.id)
  end

  def assert_bulk_status(user, action, status)
    bulk_action(action, [user.id])
    assert_redirected_to root_path
    assert_equal status, user.reload.status
    assert_empty user.sessions
  end

  def assert_bulk_error(action, ids, message)
    bulk_action(action, ids)
    assert_redirected_to root_path
    follow_redirect!
    assert_select '[role="status"]', text: message
  end

  def assert_table_structure
    assert_select 'thead input[type="checkbox"]', count: 1
    assert_select 'tbody input[type="checkbox"]', count: 2
    assert_toolbar_labels
    assert_select 'tbody button', count: 0
    assert_select 'tbody label', count: 0
  end

  def assert_toolbar_labels
    assert_select('[role="toolbar"] button') { |buttons| assert_equal %w[Block Unblock Delete], buttons.map(&:text) }
    assert_select '[role="toolbar"] img', count: 0
    assert_select '#assistant-heading', text: 'Assistant'
    assert_select '.assistant-panel', /Enter to send.*Shift\+Enter/m
    assert_select '.assistant-panel', { text: /directory|Query used/i, count: 0 }
  end
end
