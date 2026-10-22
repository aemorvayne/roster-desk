require_relative '../test_helper'
require_relative '../support/assistant_responses'

class QueryTest < ActiveSupport::TestCase
  include AssistantResponses
  def setup
    super
    @sam = create_user(job_position: 'Editor', last_login_at: Time.utc(2026, 1, 1))
    @pat = create_user(full_name: 'Pat River', email: 'pat@example.org', status: 'blocked')
  end

  def test_combines_or_groups_and_and_conditions
    active = group(condition('status', 'equals', 'active'), condition('email', 'starts_with', 's'))
    blocked = group(condition('email', 'starts_with', 'p'))
    assert_equal [@sam.id, @pat.id].sort, query(active, blocked).ids.sort
    assert_equal [@sam.id], query(active).ids
  end

  def test_text_comparisons_are_case_insensitive
    assert_equal [@sam.id], matching('email', 'contains', 'SAM')
    assert_equal [@pat.id], matching('email', 'ends_with', '.ORG')
    assert_equal [@pat.id], matching('status', 'not_equals', 'ACTIVE')
  end

  def test_wildcards_and_sql_fragments_are_literal_values
    assert_empty matching('full_name', 'contains', '%')
    assert_empty matching('full_name', 'contains', "' OR 1=1 --")
    assert_empty matching('email', 'starts_with', '_')
    assert_equal 2, User.count
  end

  def test_missing_and_present_cover_null_dates_and_empty_job_titles
    assert_equal [@pat.id], matching('last_login_at', 'missing')
    assert_equal [@sam.id], matching('last_login_at', 'present')
    assert_equal [@pat.id], matching('job_position', 'missing')
    assert_equal [@sam.id], matching('job_position', 'present')
  end

  def test_date_comparisons_use_actual_database_timestamps
    assert_equal [@sam.id], matching('last_login_at', 'before', '2026-02-01T00:00:00Z')
    assert_equal [@sam.id], matching('last_login_at', 'after', '2025-12-01T00:00:00Z')
    assert_empty matching('last_login_at', 'after', '2026-02-01T00:00:00Z')
  end

  def test_invalid_dates_and_wrong_operator_types_are_rejected
    assert_raises(DirectoryAssistant::Error) { matching('last_login_at', 'before', 'not a date') }
    assert_raises(DirectoryAssistant::Error) { matching('last_login_at', 'contains', '2026') }
    assert_raises(DirectoryAssistant::Error) { matching('email', 'before', '2026-01-01') }
  end

  def query(*groups)
    DirectoryAssistant::Query.new(User.all, groups).call
  end

  def matching(field, operator, value = '')
    query(group(condition(field, operator, value))).ids
  end
end
