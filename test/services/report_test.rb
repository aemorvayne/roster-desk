require_relative '../test_helper'
require_relative '../support/assistant_responses'

class ReportTest < ActiveSupport::TestCase
  include AssistantResponses
  def test_counts_and_lists_matching_users
    user = create_user
    assert_equal 'Matching users: 1.', report.text
    assert_includes report(metric: 'list').text, 'Sam Rowan (sam@example.com)'
    assert_equal [user.id], report.visible_users.ids
    assert_empty report.selected_ids
  end

  def test_counts_more_rows_than_the_list_limit
    populate_users
    result = report(metric: 'list')
    assert_includes result.text, 'Matching users: 21. Showing 20:'
  end

  def test_groups_by_status_job_title_and_email_domain
    create_user
    create_user(email: 'pat@example.org', job_position: 'Editor', status: 'blocked')
    assert_equal '2 users. active: 1; blocked: 1', report(metric: 'breakdown').text
    assert_equal '2 users. Not specified: 1; Editor: 1', report(metric: 'breakdown', group_by: 'job_position').text
    assert_equal '2 users. example.com: 1; example.org: 1', report(metric: 'breakdown', group_by: 'email_domain').text
  end

  def test_selection_and_filtering_do_not_change_database_records
    user = create_user
    assert_equal [user.id], report(intent: 'select').selected_ids
    assert_equal '1 user selected.', report(intent: 'select').text
    assert_equal '1 user shown.', report(intent: 'filter').text
    assert_equal [user.id], report(intent: 'filter').visible_users.ids
  end

  def test_unsupported_requests_explain_available_operations
    assert_includes report(intent: 'unsupported').text, 'Use the toolbar'
    assert_empty report(intent: 'unsupported').selected_ids
  end

  def report(**values)
    DirectoryAssistant::Report.new(plan(**values), User.all)
  end

  def populate_users
    ReportTest::TOTAL_USERS.times { |index| create_user(full_name: "Person #{index}", email: "person#{index}@example.com") }
  end
  TOTAL_USERS = DirectoryAssistant::Report::LIST_LIMIT.next
end
