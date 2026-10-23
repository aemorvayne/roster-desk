require_relative '../test_helper'

class ErrorPageTest < ActionDispatch::IntegrationTest
  def test_unknown_urls_show_a_page_with_a_working_return_link
    Rails.application.stub(:env_config, public_errors) { get '/missing-page' }
    assert_response :not_found
    assert_select 'h1', text: "This page isn't here."
    assert_select 'a[href="/"]', text: 'Back to Roster Desk'
    assert_anonymous_return_path
  end

  def public_errors
    Rails.application.env_config.merge('action_dispatch.show_exceptions' => :all,
                                       'action_dispatch.show_detailed_exceptions' => false)
  end

  def assert_anonymous_return_path
    get root_path
    assert_redirected_to new_session_path
    follow_redirect!
    assert_select 'input[type="submit"][value="Sign in"]'
  end
end
