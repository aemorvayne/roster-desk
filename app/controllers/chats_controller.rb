class ChatsController < ApplicationController
  REQUEST_LIMIT = 10
  REQUEST_WINDOW = 1.minute
  rate_limit to: REQUEST_LIMIT, within: REQUEST_WINDOW, by: -> { current_user.id }, with: :rate_limited, only: :create
  rescue_from DirectoryAssistant::Error, with: :assistant_error
  def show
    redirect_to root_path
  end

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
    render_error(error.message, :unprocessable_content)
  end

  def rate_limited
    render_error('Please wait a minute before asking another question.', :too_many_requests)
  end

  def render_error(message, status)
    @users = User.recent
    flash.now[:alert] = message
    render 'users/index', status: status
  end
end
