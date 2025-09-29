require "test_helper"

class OrganizationSwitcherControllerTest < ActionDispatch::IntegrationTest
  test "should get switch" do
    get organization_switcher_switch_url
    assert_response :success
  end
end
