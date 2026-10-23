require_relative 'browser_helper'

class AccessBrowserTest < BrowserTestCase
  def test_blocking_from_another_session_keeps_the_open_page_until_an_action
    @user = create_user
    browser_sign_in(@user)
    block_from_another_session
    assert_open_page
    assert_next_action_redirects('Unblock', 'Your account is blocked.')
  end

  def test_deletion_keeps_the_open_page_until_an_action
    user = create_user
    browser_sign_in(user)
    BulkUsers.new.call('delete', [user.id])
    assert_open_page
    assert_next_action_redirects('Block', 'Your account has been deleted.')
  end

  def block_from_another_session
    using_session(:other_browser) { block_own_account }
  end

  def block_own_account
    browser_sign_in(@user)
    check 'Select Sam Rowan'
    click_button 'Block'
    assert_text 'Your account is blocked.'
  end

  def assert_open_page
    assert_current_path root_path
    assert_text 'Your people'
    assert_selector 'tbody tr', text: /Sam Rowan.*Active/m
  end

  def assert_next_action_redirects(action, message)
    check 'Select Sam Rowan'
    click_button action
    assert_current_path new_session_path
    assert_text message
  end
end
