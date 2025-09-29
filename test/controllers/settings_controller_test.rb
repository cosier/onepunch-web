require "test_helper"

class SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @user.update(current_organization: @organization)
    sign_in @user
  end

  test "should get index when authenticated" do
    get settings_url
    assert_response :success
    assert_not_nil assigns(:organizations)
    assert_not_nil assigns(:organization)
  end

  test "should get organization when authenticated" do
    get settings_organization_url
    assert_response :success
    assert_not_nil assigns(:organizations)
    assert_not_nil assigns(:organization)
    assert_not_nil assigns(:settings)
  end

  test "should get profile when authenticated" do
    get settings_profile_url
    assert_response :success
  end

  test "should get billing when authenticated" do
    get settings_billing_url
    assert_response :success
  end

  test "should redirect to login when not authenticated" do
    sign_out @user
    get settings_organization_url
    assert_redirected_to login_url
  end

  test "should redirect to onboarding if no current organization" do
    @user.update(current_organization: nil)
    get settings_organization_url
    assert_redirected_to onboarding_path
  end

  test "organization page should include all user organizations" do
    org2 = organizations(:two)
    @user.organizations << org2

    get settings_organization_url

    organizations = assigns(:organizations)
    assert_includes organizations, @organization
    assert_includes organizations, org2
  end

  private

  def sign_in(user)
    post login_url, params: { email: user.email, password: 'password' }
  end

  def sign_out(user)
    delete logout_url
  end
end