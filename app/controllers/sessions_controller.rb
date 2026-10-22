class SessionsController < ApplicationController
  skip_before_action :require_user, only: %i[new create]
  def new; end

  def create
    user = User.authenticate_by(email: params[:email], password: params[:password])
    return reject_login unless user&.active?
    reset_session
    session[:login_id] = Session.start(user).id
    redirect_to root_path, notice: 'Welcome back.'
  end

  def destroy
    Session.find(session[:login_id]).destroy!
    reset_session
    redirect_to new_session_path, notice: 'You have signed out.'
  end

  private
  def reject_login
    flash.now[:alert] = 'Email or password is incorrect, or this account is blocked.'
    render :new, status: :unprocessable_content
  end
end
