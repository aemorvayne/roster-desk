require_relative 'browser_helper'

class LayoutBrowserTest < BrowserTestCase
  MOBILE_WIDTH = 390
  def test_assistant_is_to_the_right_on_desktop
    browser_sign_in(create_user)
    users, assistant = panel_bounds
    assert_operator assistant.fetch('left'), :>=, users.fetch('right')
    assert_equal users.fetch('top'), assistant.fetch('top')
  end

  def test_assistant_stacks_below_users_on_mobile
    browser_sign_in(create_user)
    mobile_viewport(MOBILE_WIDTH)
    users, assistant = panel_bounds
    assert_operator assistant.fetch('top'), :>=, users.fetch('bottom')
    refute page.evaluate_script('document.documentElement.scrollWidth > window.innerWidth')
  end

  def panel_bounds
    page.evaluate_script('[".users-panel", ".assistant-panel"].map(selector => ' \
                         'document.querySelector(selector).getBoundingClientRect().toJSON())')
  end
end
