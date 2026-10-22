class ApplicationController < ActionController::Base
  before_action :require_user
  before_action :prevent_caching
  helper_method :current_user
  rescue_from ActionController::InvalidAuthenticityToken, with: :expired_form
  private
  def current_user
    @current_user ||= Session.find_by(id: session[:login_id])&.user
  end

  def require_user
    return if current_user&.active?
    reset_session
    redirect_to new_session_path, alert: 'Please sign in with an active account.'
  end

  def prevent_caching
    response.headers['Cache-Control'] = 'no-store'
  end

  def expired_form
    redirect_to new_session_path, alert: 'This form expired. Please sign in and try again.'
  end
end
