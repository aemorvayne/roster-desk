require_relative '../test_helper'

class OrderingTest < ActiveSupport::TestCase
  def test_orders_recent_sign_ins_before_users_who_have_never_signed_in
    never = create_user
    earlier = create_user(email: 'earlier@example.com', last_login_at: Time.utc(2025))
    later = create_user(email: 'later@example.com', last_login_at: Time.utc(2026))
    assert_equal [later.id, earlier.id, never.id], User.directory_order(nil).ids
    assert_equal User.recent.ids, User.directory_order('invalid SQL').ids
  end

  def test_sorts_by_each_allowlisted_field
    second = create_user(full_name: 'Zoe Brook', email: 'zoe@example.org', status: 'blocked')
    first = create_user(full_name: 'Alex Rowan', email: 'alex@example.org')
    User::SORT_FIELDS.each { |field| assert_equal [first.id, second.id], User.directory_order(field).ids }
  end
end
