require_relative '../test_helper'
require_relative '../support/assistant_responses'

class ReportTest < ActiveSupport::TestCase
  include AssistantResponses
  def test_counts_and_lists_matching_users
    user = create_user
    assert_equal '1 user in total.', report.text
    assert_includes report(metric: 'list').text, 'Sam Rowan (sam@example.com)'
    assert_equal [user.id], report.visible_users.ids
    assert_empty report.selected_ids
  end

  def test_counts_more_rows_than_the_list_limit
    populate_users
    result = report(metric: 'list')
    assert_includes result.text, '21 users in total. Here are 20 of them:'
  end

  def test_groups_by_status_job_title_and_email_domain
    create_user
    create_user(email: 'pat@example.org', job_position: 'Editor', status: 'blocked')
    assert_breakdown '2 users in total: Active: 1; Blocked: 1.', 'status'
    assert_breakdown '2 users in total: Not specified: 1; Editor: 1.', 'job_position'
    assert_breakdown '2 users in total: example.com: 1; example.org: 1.', 'email_domain'
  end

  def test_selection_and_filtering_do_not_change_database_records
    user = create_user
    assert_equal [user.id], report(intent: 'select').selected_ids
    assert_equal 'Selected 1 user.', report(intent: 'select').text
    assert_equal 'Showing 1 user.', report(intent: 'filter').text
    assert_equal [user.id], report(intent: 'filter').visible_users.ids
  end

  def test_unsupported_requests_explain_available_operations
    assert_includes report(intent: 'unsupported').text, 'Use the toolbar'
    assert_empty report(intent: 'unsupported').selected_ids
  end

  def report(**values)
    DirectoryAssistant::Report.new(plan(**values), User.all)
  end

  def assert_breakdown(expected, field)
    assert_equal expected, report(metric: 'breakdown', group_by: field).text
  end

  def populate_users
    ReportTest::TOTAL_USERS.times { |index| create_user(full_name: "Person #{index}", email: "person#{index}@example.com") }
  end
  TOTAL_USERS = DirectoryAssistant::Report::LIST_LIMIT.next
end
