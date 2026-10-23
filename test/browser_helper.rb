require_relative 'test_helper'
require 'capybara/minitest'
require 'selenium-webdriver'
require_relative 'support/browser_coverage'

Capybara.app = BrowserCoverage.new(Rails.application)
Capybara.server = :puma, { Silent: true }
Capybara.enable_aria_label = true
Capybara.default_max_wait_time = 5
Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless=new')
  options.add_argument('--window-size=1440,1000')
  options.add_argument('--no-sandbox') if ENV['CI']
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

class BrowserTestCase < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers
  include Capybara::DSL
  include Capybara::Minitest::Assertions
  MOBILE_HEIGHT = 844
  DEVICE_SCALE = 1
  def setup
    super
    Capybara.current_driver = :headless_chrome
    page.driver.browser.manage.window.resize_to(1440, 1000)
    page.driver.browser.execute_cdp('Emulation.clearDeviceMetricsOverride')
  end

  def teardown
    BrowserCoverage.save(page.evaluate_script('window.__coverage__ || {}'))
    Capybara.reset_sessions!
    Capybara.use_default_driver
    super
  end

  def browser_sign_in(user)
    visit new_session_path
    fill_in 'Email', with: user.email
    fill_in 'Password', with: 'x'
    submit_sign_in
  end

  def submit_sign_in
    click_button 'Sign in'
    assert_current_path root_path
    assert_text 'Your people'
  end

  def mobile_viewport(width)
    page.driver.browser.execute_cdp('Emulation.setDeviceMetricsOverride', width: width, height: MOBILE_HEIGHT,
                                                                          deviceScaleFactor: DEVICE_SCALE, mobile: true)
  end
end
