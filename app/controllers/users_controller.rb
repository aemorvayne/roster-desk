class UsersController < ApplicationController
  rescue_from BulkUsers::InvalidSelection, with: :invalid_selection
  def index
    @users = User.recent
  end

  def bulk
    count = BulkUsers.new.call(params[:operation], params[:user_ids])
    notice = "#{count} user(s) updated."
    return redirect_to(root_path, notice: notice) if Session.exists?(id: session[:login_id])
    reset_session
    redirect_to new_session_path, notice: "#{notice} Your account is no longer signed in."
  end

  private
  def invalid_selection(error)
    redirect_to root_path, alert: error.message
  end
end
