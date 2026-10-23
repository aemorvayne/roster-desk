require_relative '../test_helper'
require_relative '../support/assistant_responses'

class ReportWordingTest < ActiveSupport::TestCase
  include AssistantResponses
  def test_blocked_counts_use_the_status_and_correct_grammar
    assert_equal '0 users are blocked.', status_report('blocked').text
    create_user(status: 'blocked')
    assert_equal '1 user is blocked.', status_report('BLOCKED').text
    create_user(status: 'blocked', email: 'pat@example.com')
    assert_equal '2 users are blocked.', status_report('blocked').text
  end

  def test_active_counts_describe_active_users
    create_user
    assert_equal '1 user is active.', status_report('active').text
  end

  def test_text_criteria_use_a_natural_summary
    create_user
    result = report(group(condition('email', 'contains', 'sam')))
    assert_equal 'I found 1 user matching your criteria.', result.text
  end

  def test_multiple_conditions_do_not_describe_a_status_total
    create_user
    filters = group(condition('status', 'equals', 'active'), condition('email', 'contains', 'sam'))
    assert_equal 'I found 1 user matching your criteria.', report(filters).text
  end

  def test_alternative_groups_do_not_describe_one_status_total
    create_user
    filters = %w[active blocked].map { |status| group(condition('status', 'equals', status)) }
    assert_equal 'I found 1 user matching your criteria.', report(*filters).text
  end

  def test_unknown_status_values_are_not_used_as_response_text
    assert_equal 'I found 0 users matching your criteria.', status_report('unknown').text
  end

  def test_empty_lists_and_breakdowns_have_no_empty_suffix
    assert_equal '0 users in total.', report(metric: 'list').text
    assert_equal '0 users in total.', report(metric: 'breakdown').text
  end

  def status_report(status)
    report(group(condition('status', 'equals', status)))
  end

  def report(*groups, **values)
    DirectoryAssistant::Report.new(plan(groups: groups, **values), User.all)
  end
end
