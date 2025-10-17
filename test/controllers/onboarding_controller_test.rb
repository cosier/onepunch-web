require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get onboarding_new_url
    assert_response :success
  end

  test "should get create" do
    get onboarding_create_url
    assert_response :success
  end

  test "should get update" do
    get onboarding_update_url
    assert_response :success
  end

  test "should get complete" do
    get onboarding_complete_url
    assert_response :success
  end
end
