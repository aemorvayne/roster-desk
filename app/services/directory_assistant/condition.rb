class DirectoryAssistant
  class Condition
    TEXT_OPERATORS = %w[equals not_equals contains starts_with ends_with missing present].freeze
    DATE_OPERATORS = %w[before after missing present].freeze
    COMPARISONS = { 'before' => :lt, 'after' => :gt }.freeze
    def initialize(condition)
      @field, @operator, @value = condition.values_at('field', 'operator', 'value')
    end

    def to_arel
      validate_operator
      return nullable_condition if %w[missing present].include?(@operator)
      return date_condition if @field == 'last_login_at'
      text_condition
    end

    def validate_operator
      allowed = @field == 'last_login_at' ? DATE_OPERATORS : TEXT_OPERATORS
      raise Error, 'That comparison is not supported for this field.' unless allowed.include?(@operator)
    end

    def column
      User.arel_table[@field]
    end

    def nullable_condition
      missing = column.eq(nil)
      missing = missing.or(column.eq('')) unless @field == 'last_login_at'
      @operator == 'missing' ? missing : missing.not
    end

    def date_condition
      date = Time.iso8601(@value)
      column.public_send(COMPARISONS.fetch(@operator), date)
    rescue ArgumentError
      raise Error, 'Please use a valid date and time for last sign-in comparisons.'
    end

    def text_condition
      value = @value.downcase
      return column.lower.eq(value) if @operator == 'equals'
      return column.lower.not_eq(value) if @operator == 'not_equals'
      column.matches(pattern(value), nil, false)
    end

    def pattern(value)
      escaped = User.sanitize_sql_like(value)
      return "#{escaped}%" if @operator == 'starts_with'
      return "%#{escaped}" if @operator == 'ends_with'
      "%#{escaped}%"
    end
  end
end
