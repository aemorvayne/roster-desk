class ApplicationController < ActionController::Base
  prepend_before_action :require_user
  before_action :prevent_caching
  helper_method :current_user
  rescue_from ActionController::InvalidAuthenticityToken, with: :expired_form
  private
  def current_user
    @current_user ||= Session.find_by(id: session[:login_id])&.user
  end

  def require_user
    return if current_user&.active?
    reject_access
  end

  def reject_access
    message = access_message
    reset_session
    redirect_to new_session_path, alert: message
  end

  def access_message
    return 'Please sign in to continue.' unless session[:user_id]
    user = User.find_by(id: session[:user_id])
    return 'Your account has been deleted. Please sign in with another account.' unless user
    user.active? ? 'Your session has ended. Please sign in again.' : 'Your account is blocked. Please sign in again.'
  end

  def prevent_caching
    response.headers['Cache-Control'] = 'no-store'
  end

  def expired_form
    redirect_to new_session_path, alert: 'This form expired. Please sign in and try again.'
  end
end
