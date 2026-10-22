require_relative 'browser_helper'

class BrowserTest < BrowserTestCase
  def test_selection_toolbar_and_self_blocking
    user = create_user
    create_user(full_name: 'Pat River', email: 'pat@example.com')
    browser_sign_in(user)
    manage_other_user
    block_everyone
  end

  def test_empty_selection_and_mobile_layout
    browser_sign_in(create_user)
    page.driver.browser.manage.window.resize_to(390, 844)
    refute page.evaluate_script('document.documentElement.scrollWidth > window.innerWidth')
    check 'Select all users'
    clear_selection
  end

  def test_registration_and_login_in_the_browser
    visit new_registration_path
    complete_registration
    assert_text 'Your account is ready'
    browser_sign_in(User.find_by!(email: 'new@example.com'))
    assert_selector 'tbody tr', count: 1
  end

  def complete_registration
    fill_in 'Full name', with: 'New Person'
    fill_in 'Email', with: 'new@example.com'
    fill_in 'Password', with: 'x'
    click_button 'Create account'
  end

  def manage_other_user
    check 'Select Pat River'
    assert_selector '[data-selection-target="count"]', text: '1 selected'
    click_button 'Block'
    assert_selector 'tbody tr', text: /Pat River.*Blocked/m
    unblock_other_user
  end

  def unblock_other_user
    check 'Select Pat River'
    click_button 'Unblock'
    assert_selector 'tbody tr', text: /Pat River.*Active/m
    assert_equal 'active', User.find_by!(email: 'pat@example.com').status
  end

  def block_everyone
    check 'Select all users'
    assert_selector '[data-selection-target="count"]', text: '2 selected'
    click_button 'Block'
    assert_text 'Your account is no longer signed in'
    assert_equal ['blocked'], User.distinct.pluck(:status)
  end

  def clear_selection
    uncheck 'Select all users'
    assert_selector '[data-selection-target="count"]', text: '0 selected'
    assert_button 'Block', disabled: true
  end
end
