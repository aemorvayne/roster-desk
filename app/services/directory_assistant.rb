class DirectoryAssistant
  MAX_QUESTION_LENGTH = 1200
  class Error < StandardError
  end

  def initialize(planner:)
    @planner = planner
  end

  def call(question)
    raise Error, 'Enter a question about the directory.' if question.blank?
    raise Error, 'Please shorten your question.' if question.length > MAX_QUESTION_LENGTH
    Report.new(@planner.call(question), User.all)
  end
end
