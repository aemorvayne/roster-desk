class BulkUsers
  ACTIONS = %w[block unblock delete].freeze
  InvalidSelection = Class.new(StandardError)
  def call(action, ids)
    raise InvalidSelection, 'Choose a valid action.' unless ACTIONS.include?(action)
    users = User.where(id: validated_ids(ids))
    raise InvalidSelection, 'Select at least one existing user.' unless users.exists?
    User.transaction { apply(action, users) }
  end

  private
  def validated_ids(ids)
    ids = ids.compact_blank if ids.is_a?(Array)
    return [] if ids.blank?
    return ids if ids.is_a?(Array) && ids.all? { |id| id.to_s.match?(/\A[1-9]\d*\z/) }
    raise InvalidSelection, 'Select users using the checkboxes.'
  end

  def apply(action, users)
    return users.delete_all if action == 'delete'
    Session.where(user_id: users.select(:id)).delete_all if action == 'block'
    users.update_all(status: action == 'block' ? 'blocked' : 'active', updated_at: Time.current)
  end
end
