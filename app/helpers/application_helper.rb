module ApplicationHelper
  def login_time(user)
    return 'Never signed in' unless user.last_login_at
    user.last_login_at.utc.strftime('%d %b %Y · %H:%M UTC')
  end
end
