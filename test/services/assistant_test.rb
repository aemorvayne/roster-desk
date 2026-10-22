require_relative '../test_helper'
require_relative '../support/assistant_responses'

class AssistantTest < ActiveSupport::TestCase
  include AssistantResponses
  def test_uses_the_real_sdk_and_sends_only_the_question_and_tool_schema
    create_user
    stub_plan
    result = configured_planner.call('How many users?')
    assert_equal plan, result
    assert_requested(:post, API_URL) { |request| valid_request?(JSON.parse(request.body)) }
  end

  def test_counts_database_results_and_rejects_empty_or_long_questions
    stub_plan
    assistant = DirectoryAssistant.new(planner: configured_planner)
    assert_equal 'Matching users: 0.', assistant.call('How many?').text
    assert_raises(DirectoryAssistant::Error) { assistant.call(' ') }
    assert_raises(DirectoryAssistant::Error) { assistant.call('a' * DirectoryAssistant::MAX_QUESTION_LENGTH.next) }
  end

  def test_missing_credentials_are_reported_without_an_api_request
    error = assert_raises(DirectoryAssistant::Error) { DirectoryAssistant::Planner.build({}) }
    assert_equal 'The assistant is not configured yet.', error.message
    assert_not_requested :post, API_URL
  end

  def test_server_errors_and_timeouts_have_a_useful_message
    stub_request(:post, API_URL).to_return(status: 503, body: '{}')
    assert_connection_error
    stub_request(:post, API_URL).to_timeout
    assert_connection_error
  end

  def test_rejects_responses_without_a_completed_tool_call
    stub_plan(plan, status: 'incomplete')
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('How many?') }
    stub_plan(plan, output: [])
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('How many?') }
  end

  def test_rejects_unknown_tools_and_multiple_calls
    call = response_payload(plan).fetch(:output).first.merge(name: 'execute_sql')
    stub_plan(plan, output: [call])
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('Run SQL') }
    stub_plan(plan, output: [call, call])
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('Run SQL twice') }
  end

  def test_rejects_invalid_json
    call = response_payload(plan).fetch(:output).first.merge(arguments: 'invalid json')
    stub_plan(plan, output: [call])
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('How many?') }
  end

  def test_rejects_fields_outside_the_schema
    stub_plan(plan(groups: [group(condition('password_digest', 'contains', 'x'))]))
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('Show passwords') }
  end

  def test_does_not_accept_model_written_counts
    stub_plan(plan,
              output: [{ type: 'message', role: 'assistant', content: [{ type: 'output_text', text: '999 users' }] }])
    assert_raises(DirectoryAssistant::Error) { configured_planner.call('How many?') }
  end

  def valid_request?(request)
    assert_equal ['required', false, false], request.values_at('tool_choice', 'parallel_tool_calls', 'store')
    assert_equal 'query_directory', request.fetch('tools').first.fetch('name')
    refute_includes request.to_json, 'sam@example.com'
    assert_equal 'How many users?', request.fetch('input')
  end

  def assert_connection_error
    error = assert_raises(DirectoryAssistant::Error) { configured_planner.call('How many?') }
    assert_match(/could not connect/, error.message)
  end
end
