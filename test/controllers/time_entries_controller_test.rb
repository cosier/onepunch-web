require "test_helper"

class TimeEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @organization = organizations(:one)
    @project = projects(:one)
    @project.update(organization: @organization)
    @user.update(current_organization: @organization)

    @time_entry = time_entries(:one)
    @time_entry.update(user: @user, project: @project)

    sign_in @user
  end

  test "should get index" do
    get time_entries_url
    assert_response :success
    assert_not_nil assigns(:time_entries)
    assert_not_nil assigns(:projects)
  end

  test "should get new" do
    get new_time_entry_url
    assert_response :success
  end

  test "should create time entry" do
    assert_difference("TimeEntry.count") do
      post time_entries_url, params: {
        time_entry: {
          project_id: @project.id,
          description: "New entry",
          started_at: 1.hour.ago,
          ended_at: Time.current,
          billable: true
        }
      }
    end

    assert_redirected_to time_entries_url
  end

  test "should show time entry" do
    get time_entry_url(@time_entry)
    assert_response :success
  end

  test "should get edit" do
    get edit_time_entry_url(@time_entry)
    assert_response :success
  end

  test "should update time entry" do
    patch time_entry_url(@time_entry), params: {
      time_entry: {
        description: "Updated description"
      }
    }
    assert_redirected_to time_entries_url
  end

  test "should destroy time entry" do
    assert_difference("TimeEntry.count", -1) do
      delete time_entry_url(@time_entry)
    end

    assert_redirected_to time_entries_url
  end

  test "should stop running time entry" do
    @time_entry.update(ended_at: nil)

    post stop_time_entry_url(@time_entry)

    @time_entry.reload
    assert_not_nil @time_entry.ended_at
  end

  test "should not stop already stopped entry" do
    @time_entry.update(ended_at: 1.hour.ago)

    post stop_time_entry_url(@time_entry)

    assert_redirected_to time_entries_url
  end

  test "should resume time entry" do
    @time_entry.update(ended_at: 1.hour.ago)

    assert_difference("TimeEntry.count") do
      post resume_time_entry_url(@time_entry)
    end

    new_entry = TimeEntry.last
    assert_nil new_entry.ended_at
    assert_equal @time_entry.project_id, new_entry.project_id
    assert_equal @time_entry.description, new_entry.description
  end

  test "should stop other running entries when resuming" do
    running_entry = time_entries(:two)
    running_entry.update(user: @user, project: @project, ended_at: nil)

    post resume_time_entry_url(@time_entry)

    running_entry.reload
    assert_not_nil running_entry.ended_at
  end

  test "should respond with turbo stream for ajax delete" do
    delete time_entry_url(@time_entry), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  test "should respond with turbo stream for ajax stop" do
    @time_entry.update(ended_at: nil)

    post stop_time_entry_url(@time_entry), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  test "should respond with turbo stream for ajax resume" do
    post resume_time_entry_url(@time_entry), headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  private

  def sign_in(user)
    post login_url, params: { email: user.email, password: 'password' }
  end
end