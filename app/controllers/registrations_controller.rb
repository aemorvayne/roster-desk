class RegistrationsController < ApplicationController
  skip_before_action :require_user
  rescue_from ActiveRecord::RecordNotUnique, with: :duplicate_email
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_user
  def new
    @user = User.new
  end

  def create
    @user = User.create!(registration_params)
    redirect_to new_session_path, notice: 'Your account is ready. Sign in to continue.'
  end

  private
  def registration_params
    params.expect(user: %i[full_name email job_position password])
  end

  def duplicate_email
    @user = User.new(registration_params.except(:password))
    @user.errors.add(:email, 'is already registered')
    render :new, status: :unprocessable_content
  end

  def invalid_user(error)
    @user = error.record
    render :new, status: :unprocessable_content
  end
end
