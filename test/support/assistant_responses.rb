module AssistantResponses
  API_URL = 'https://api.openai.com/v1/responses'.freeze
  def plan(**values)
    { 'intent' => 'answer', 'metric' => 'count', 'group_by' => 'status', 'groups' => [] }.merge(values.stringify_keys)
  end

  def condition(field, operator, value = '')
    { 'field' => field, 'operator' => operator, 'value' => value }
  end

  def group(*conditions)
    { 'conditions' => conditions }
  end

  def stub_plan(value = plan, **overrides)
    stub_request(:post, API_URL).to_return(body: response_payload(value, **overrides).to_json,
                                           headers: { 'Content-Type' => 'application/json' })
  end

  def response_payload(value, **overrides)
    call = { type: 'function_call', name: 'query_directory', call_id: 'call_example', arguments: value.to_json }
    { id: 'resp_example', object: 'response', status: 'completed', output: [call] }.merge(overrides)
  end

  def configured_planner
    DirectoryAssistant::Planner.build('OPENAI_API_KEY' => 'placeholder', 'OPENAI_MODEL' => 'gpt-4.1-mini')
  end
end
