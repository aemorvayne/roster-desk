require 'securerandom'

class BrowserCoverage
  OUTPUT = File.expand_path('../../.nyc_output', __dir__).freeze
  INSTRUMENTED_SCRIPT = File.expand_path('../../tmp/instrumented/public/app.js', __dir__).freeze
  CAPTURE_SCRIPT = File.read(File.expand_path('../fixtures/capture_coverage.js', __dir__)).freeze
  def initialize(app)
    @app = app
  end

  def call(environment)
    return record(environment) if environment.fetch('PATH_INFO') == '/test-coverage'
    return script_response if environment.fetch('PATH_INFO') == '/app.js'
    allow_instrumentation(@app.call(environment))
  end

  def allow_instrumentation(response)
    return response unless response[1]['content-security-policy']
    response[1]['content-security-policy'] += "; script-src 'self' 'unsafe-eval'"
    response
  end

  def record(environment)
    self.class.save(JSON.parse(environment.fetch('rack.input').read))
    [Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(:no_content), {}, []]
  end

  def self.save(coverage)
    File.write(File.join(OUTPUT, "#{SecureRandom.uuid}.json"), JSON.generate(coverage))
  end

  def script_response
    script = [File.read(INSTRUMENTED_SCRIPT), CAPTURE_SCRIPT].join("\n")
    [Rack::Utils::SYMBOL_TO_STATUS_CODE.fetch(:ok), { 'content-type' => 'application/javascript' }, [script]]
  end
end
