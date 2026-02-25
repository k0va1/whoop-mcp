require_relative "../test_helper"

module ToolTestHelper
  private

  def mock_client
    @mock_client ||= Minitest::Mock.new
  end

  def server_context
    {whoop_client: mock_client}
  end

  def failing_client(method)
    client = Object.new
    client.define_singleton_method(method) { |*| raise Whoop::Error, "fail" }
    {whoop_client: client}
  end

  def assert_success_response(response)
    assert_instance_of MCP::Tool::Response, response
    refute response.error?
  end

  def assert_error_response(response)
    assert_instance_of MCP::Tool::Response, response
    assert response.error?
  end
end

class GetActivityMappingTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"v2_activity_id" => "ecfc6a15-4661-442f-a9a4-f160dd7afae8"}, ["v1/activity-mapping/12345"])
    response = Tools::GetActivityMapping.call(activity_v1_id: 12345, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetActivityMapping.call(activity_v1_id: 12345, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetCycleTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => 93845}, ["v2/cycle/93845"])
    response = Tools::GetCycle.call(cycle_id: 93845, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetCycle.call(cycle_id: 93845, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListCyclesTest < Minitest::Test
  include ToolTestHelper

  def test_success
    expected_params = {limit: nil, start: nil, end: nil, nextToken: nil}
    mock_client.expect(:get, {"records" => [{"id" => 1}]}, ["v2/cycle", expected_params])
    response = Tools::ListCycles.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_with_params
    expected_params = {limit: 5, start: nil, end: nil, nextToken: nil}
    mock_client.expect(:get, {"records" => []}, ["v2/cycle", expected_params])
    response = Tools::ListCycles.call(limit: 5, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListCycles.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetCycleSleepTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => "abc-123"}, ["v2/cycle/93845/sleep"])
    response = Tools::GetCycleSleep.call(cycle_id: 93845, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetCycleSleep.call(cycle_id: 93845, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetCycleRecoveryTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"cycle_id" => 93845}, ["v2/cycle/93845/recovery"])
    response = Tools::GetCycleRecovery.call(cycle_id: 93845, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetCycleRecovery.call(cycle_id: 93845, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListRecoveriesTest < Minitest::Test
  include ToolTestHelper

  def test_success
    expected_params = {limit: nil, start: nil, end: nil, nextToken: nil}
    mock_client.expect(:get, {"records" => [{"cycle_id" => 1}]}, ["v2/recovery", expected_params])
    response = Tools::ListRecoveries.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListRecoveries.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetSleepTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => "abc-123"}, ["v2/activity/sleep/abc-123"])
    response = Tools::GetSleep.call(sleep_id: "abc-123", server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetSleep.call(sleep_id: "abc-123", server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListSleepsTest < Minitest::Test
  include ToolTestHelper

  def test_success
    expected_params = {limit: nil, start: nil, end: nil, nextToken: nil}
    mock_client.expect(:get, {"records" => [{"id" => "abc"}]}, ["v2/activity/sleep", expected_params])
    response = Tools::ListSleeps.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListSleeps.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetBodyMeasurementTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"height_meter" => 1.83}, ["v2/user/measurement/body"])
    response = Tools::GetBodyMeasurement.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetBodyMeasurement.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetProfileTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"first_name" => "John"}, ["v2/user/profile/basic"])
    response = Tools::GetProfile.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetProfile.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class RevokeAccessTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:delete, nil, ["v2/user/access"])
    response = Tools::RevokeAccess.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::RevokeAccess.call(server_context: failing_client(:delete))
    assert_error_response(response)
  end
end

class GetWorkoutTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => "abc-123"}, ["v2/activity/workout/abc-123"])
    response = Tools::GetWorkout.call(workout_id: "abc-123", server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetWorkout.call(workout_id: "abc-123", server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListWorkoutsTest < Minitest::Test
  include ToolTestHelper

  def test_success
    expected_params = {limit: nil, start: nil, end: nil, nextToken: nil}
    mock_client.expect(:get, {"records" => [{"id" => "abc"}]}, ["v2/activity/workout", expected_params])
    response = Tools::ListWorkouts.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListWorkouts.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end
