class BulkUsers
  ACTIONS = %w[block unblock delete].freeze
  class InvalidSelection < StandardError; end

  def call(action, ids)
    raise InvalidSelection, 'Choose a valid action.' unless ACTIONS.include?(action)
    users = User.where(id: Array(ids).map(&:to_s))
    raise InvalidSelection, 'Select at least one existing user.' unless users.exists?
    User.transaction { apply(action, users) }
  end

  private
  def apply(action, users)
    return users.delete_all if action == 'delete'
    Session.where(user_id: users.select(:id)).delete_all if action == 'block'
    users.update_all(status: action == 'block' ? 'blocked' : 'active', updated_at: Time.current)
  end
end
