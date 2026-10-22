require_relative 'browser_helper'
require_relative 'support/assistant_responses'

class ChatBrowserTest < BrowserTestCase
  include AssistantResponses
  def test_chat_selects_matching_people_and_updates_toolbar
    with_environment('OPENAI_API_KEY' => 'placeholder') do
      prepare_directory
      ask_to_select
      assert_selection
    end
  end

  def test_chat_filters_to_an_empty_table_and_can_reset
    with_environment('OPENAI_API_KEY' => 'placeholder') do
      browser_sign_in(create_user)
      ask_to_filter
      assert_empty_table
    end
  end

  def prepare_directory
    browser_sign_in(create_user)
    create_user(full_name: 'Pat River', email: 'pat@example.org')
    create_user(full_name: 'Alex Brook', email: 'alex@example.net')
  end

  def ask_to_select
    groups = [group(condition('email', 'starts_with', 's')), group(condition('email', 'starts_with', 'p'))]
    stub_plan(plan(intent: 'select', groups: groups))
    fill_in 'Your question', with: 'Select users with emails starting with s or p'
    click_button 'Ask'
    assert_selector '.chat-answer', text: '2 users selected.'
  end

  def assert_selection
    assert_checked_field 'Select Sam Rowan'
    assert_checked_field 'Select Pat River'
    assert_unchecked_field 'Select Alex Brook'
    assert_selector '[data-selection-target="count"]', text: '2 selected'
    refute_button 'Block', disabled: true
  end

  def ask_to_filter
    stub_plan(plan(intent: 'filter', groups: [group(condition('status', 'equals', 'blocked'))]))
    fill_in 'Your question', with: 'Show blocked users'
    click_button 'Ask'
    assert_selector '.chat-answer', text: '0 users shown.'
  end

  def assert_empty_table
    assert_button 'Block', disabled: true
    assert_unchecked_field 'Select all users'
    click_link 'Clear filter'
    assert_selector 'tbody tr', count: 1
  end
end
