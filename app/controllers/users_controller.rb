class UsersController < ApplicationController
  rescue_from BulkUsers::InvalidSelection, with: :invalid_selection
  def index
    @users = User.directory_order(params[:sort])
  end

  def bulk
    count = BulkUsers.new.call(params[:operation], params[:user_ids])
    notice = "#{count} user(s) updated."
    return redirect_to(root_path, notice: notice) if Session.exists?(id: session[:login_id])
    reject_access
  end

  private
  def invalid_selection(error)
    redirect_to root_path, alert: error.message
  end
end
