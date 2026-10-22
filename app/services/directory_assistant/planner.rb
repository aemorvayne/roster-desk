class DirectoryAssistant
  class Planner
    TIMEOUT_SECONDS = 20
    NO_RETRIES = 0
    MAX_OUTPUT_TOKENS = 1500
    EXPECTED_CALLS = 1
    TOOL = JSON.parse(Rails.root.join('config/directory_tool.json').read).freeze
    SCHEMA = JSONSchemer.schema(TOOL.fetch('parameters'))
    def self.build(environment = ENV)
      key = environment['OPENAI_API_KEY']
      raise Error, 'The assistant is not configured yet.' if key.blank?
      client = OpenAI::Client.new(api_key: key, timeout: TIMEOUT_SECONDS, max_retries: NO_RETRIES, log_level: :off)
      new(client: client, model: environment.fetch('OPENAI_MODEL', 'gpt-4.1-mini'))
    end

    def initialize(client:, model:)
      @client = client
      @model = model
    end

    def call(question)
      parse(@client.responses.create(**options(question)))
    rescue OpenAI::Errors::APIError
      raise Error, 'The assistant could not connect. Please try again shortly.'
    rescue JSON::ParserError, KeyError, TypeError, OpenAI::Errors::ConversionError
      raise Error, 'The assistant returned an invalid query. Please rephrase your question.'
    end

    def options(question)
      { model: @model, input: question, instructions: instructions, tools: [TOOL], store: false,
        tool_choice: 'required', parallel_tool_calls: false, max_output_tokens: MAX_OUTPUT_TOKENS }
    end

    def instructions
      'Use query_directory for questions about users. Never guess results or generate SQL. ' \
        "Use unsupported for requests outside the tool's capabilities, including edits or deletion. " \
        "Select/filter only when explicitly requested. Last seen means last_login_at. Today is #{Date.current.iso8601}."
    end

    def parse(response)
      plan = JSON.parse(function_call(response).arguments)
      raise Error, 'The assistant returned an unsupported query.' unless SCHEMA.valid?(plan)
      plan
    end

    def function_call(response)
      calls = Array(response.output).select { |item| item.type == :function_call }
      raise Error, 'Please rephrase: no complete query was returned.' unless complete?(response, calls)
      calls.first
    end

    def complete?(response, calls)
      response.status == :completed && calls.size == EXPECTED_CALLS && calls.first.name == TOOL.fetch('name')
    end
  end
end
