require_relative 'browser_helper'
require_relative 'support/assistant_responses'

class ChatKeyboardTest < BrowserTestCase
  include AssistantResponses
  def test_enter_sends_the_message
    with_environment('OPENAI_API_KEY' => 'placeholder') do
      prepare_chat
      fill_in 'Your question', with: 'How many users?'
      send_message
    end
  end

  def test_shift_enter_adds_a_newline_without_sending
    with_environment('OPENAI_API_KEY' => 'placeholder') do
      prepare_chat
      type_multiline_message
      send_message
    end
  end

  def test_enter_cannot_send_an_empty_message
    prepare_chat
    find_field('Your question').send_keys(:enter)
    assert_field 'Your question', with: ''
    refute page.evaluate_script('document.querySelector("textarea").checkValidity()')
    assert_not_requested :post, API_URL
  end

  def test_composition_enter_does_not_send_an_unfinished_character
    prepare_chat
    fill_in 'Your question', with: 'How many users?'
    assert composition_enter
    assert_field 'Your question', with: 'How many users?'
    assert_not_requested :post, API_URL
  end

  def prepare_chat
    browser_sign_in(create_user)
    stub_plan
  end

  def send_message
    find_field('Your question').send_keys(:enter)
    assert_selector '.chat-answer', text: '1 user in total.'
    assert_requested :post, API_URL, times: 1
  end

  def type_multiline_message
    fill_in 'Your question', with: 'How many'
    find_field('Your question').send_keys(%i[shift enter], 'users?')
    assert_field 'Your question', with: "How many\nusers?"
    assert_not_requested :post, API_URL
  end

  def composition_enter
    page.evaluate_script('document.querySelector("textarea").dispatchEvent(new KeyboardEvent("keydown", ' \
                         '{key: "Enter", isComposing: true, bubbles: true, cancelable: true}))')
  end
end
