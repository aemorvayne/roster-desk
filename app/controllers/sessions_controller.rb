class SessionsController < ApplicationController
  skip_before_action :require_user, only: %i[new create]
  def new; end

  def create
    user = authenticated_user
    return reject_login unless user&.active?
    start_session(user)
    redirect_to root_path, notice: 'Welcome back.'
  end

  def destroy
    Session.find(session[:login_id]).destroy!
    reset_session
    redirect_to new_session_path, notice: 'You have signed out.'
  end

  private
  def start_session(user)
    reset_session
    session[:login_id] = Session.start(user).id
    session[:user_id] = user.id
  end

  def authenticated_user
    credentials = params.permit(:email, :password)
    User.authenticate_by(email: credentials[:email], password: credentials[:password])
  end

  def reject_login
    flash.now[:alert] = 'Email or password is incorrect, or this account is blocked.'
    render :new, status: :unprocessable_content
  end
end
