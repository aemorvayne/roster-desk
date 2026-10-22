class ChatsController < ApplicationController
  REQUEST_LIMIT = 10
  REQUEST_WINDOW = 1.minute
  rate_limit to: REQUEST_LIMIT, within: REQUEST_WINDOW, by: -> { current_user.id }, with: :rate_limited
  rescue_from DirectoryAssistant::Error, with: :assistant_error
  def create
    @question = params.expect(:question)
    @report = assistant.call(@question)
    @users = @report.visible_users.recent
    @selected_ids = @report.selected_ids
    render 'users/index'
  end
  private
  def assistant
    DirectoryAssistant.new(planner: DirectoryAssistant::Planner.build)
  end

  def assistant_error(error)
    @users = User.recent
    flash.now[:alert] = error.message
    render 'users/index', status: :unprocessable_content
  end

  def rate_limited
    @users = User.recent
    flash.now[:alert] = 'Please wait a minute before asking another question.'
    render 'users/index', status: :too_many_requests
  end
end
