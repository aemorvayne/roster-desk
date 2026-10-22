require_relative '../test_helper'

class ConcurrencyTest < ActiveSupport::TestCase
  CONCURRENT_WRITERS = 2
  def test_database_allows_only_one_of_two_competing_registrations
    threads = Array.new(CONCURRENT_WRITERS) { Thread.new { register_with_connection } }
    assert_equal %i[created duplicate], threads.map(&:value).sort
    assert_equal 1, User.count
  end

  def register_with_connection
    ActiveRecord::Base.connection_pool.with_connection { register_once }
  end

  def register_once
    create_user
    :created
  rescue ActiveRecord::RecordNotUnique
    :duplicate
  end
end
