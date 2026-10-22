require_relative '../test_helper'
require_relative '../support/assistant_responses'

class ChatsTest < ActionDispatch::IntegrationTest
  include AssistantResponses
  def setup
    super
    @original_key = ENV.fetch('OPENAI_API_KEY', nil)
    ENV['OPENAI_API_KEY'] = 'placeholder'
  end

  def teardown
    ENV['OPENAI_API_KEY'] = @original_key
    super
  end

  def test_requires_an_active_login_before_contacting_openai
    post chat_path, params: { question: 'Count users' }
    assert_redirected_to new_session_path
    assert_not_requested :post, API_URL
  end

  def test_answers_with_calculated_counts_and_shows_the_query
    sign_in
    stub_plan
    ask('How many users?')
    assert_select '.chat-answer', text: 'Matching users: 1.'
    assert_select 'details', /Query used/
  end

  def test_selects_matching_checkboxes
    user = sign_in
    stub_plan(plan(intent: 'select'))
    ask('Select everyone')
    assert_select "input[name='user_ids[]'][value='#{user.id}'][checked]"
    assert_select '.chat-answer', text: '1 user selected.'
  end

  def test_filters_the_table_and_reports_no_matches
    sign_in
    stub_plan(plan(intent: 'filter', groups: [group(condition('status', 'equals', 'blocked'))]))
    ask('Show blocked users')
    assert_select 'tbody tr', count: 0
    assert_select '.chat-answer', text: '0 users shown.'
  end

  def test_shows_service_failures_without_losing_the_directory
    sign_in
    stub_request(:post, API_URL).to_timeout
    ask('Count users')
    assert_response :unprocessable_content
    assert_select 'tbody tr', count: 1
  end

  def test_limits_requests_before_calling_the_provider_again
    sign_in
    stub_plan
    ChatsController::REQUEST_LIMIT.times { ask('Count users') }
    assert_rate_limit
    assert_requested :post, API_URL, times: ChatsController::REQUEST_LIMIT
  end

  def assert_rate_limit
    ask('Count users')
    assert_response :too_many_requests
    assert_select '[role="status"]', /wait a minute/
  end

  def ask(question)
    submit_form(root_path, chat_path, question: question)
  end
end
