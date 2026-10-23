require_relative '../test_helper'
require_relative '../support/assistant_responses'

class ChatNavigationTest < ActionDispatch::IntegrationTest
  include AssistantResponses
  def test_reopening_chat_without_a_session_shows_the_login_page
    get chat_path
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select 'input[type="submit"][value="Sign in"]'
    assert_not_requested :post, API_URL
  end

  def test_reopening_chat_returns_to_the_users_page
    sign_in
    get chat_path
    assert_users_redirect
    assert_not_requested :post, API_URL
  end

  def test_chat_links_support_head_requests
    sign_in
    head chat_path
    assert_redirected_to root_path
    assert_empty response.body
    assert_not_requested :post, API_URL
  end

  def test_reopening_chat_does_not_consume_the_message_allowance
    with_environment('OPENAI_API_KEY' => 'placeholder') do
      reopen_chat_repeatedly
      ask_after_reopening
    end
  end

  def reopen_chat_repeatedly
    sign_in
    ChatsController::REQUEST_LIMIT.times do
      get chat_path
      assert_redirected_to root_path
    end
  end

  def ask_after_reopening
    stub_plan
    submit_form(root_path, chat_path, question: 'How many users?')
    assert_response :success
    assert_select '.chat-answer', text: '1 user in total.'
    assert_requested :post, API_URL, times: 1
  end

  def assert_users_redirect
    assert_redirected_to root_path
    follow_redirect!
    assert_response :success
    assert_select 'tbody tr', count: 1
    assert_select '#assistant-heading', text: 'Assistant'
  end
end
