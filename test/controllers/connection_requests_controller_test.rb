require 'test_helper'

class ConnectionRequestsControllerTest < ActionController::TestCase
  setup do
    @connection_request = connection_requests(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:connection_requests)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create connection_request" do
    assert_difference('ConnectionRequest.count') do
      post :create, connection_request: {  }
    end

    assert_redirected_to connection_request_path(assigns(:connection_request))
  end

  test "should show connection_request" do
    get :show, id: @connection_request
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @connection_request
    assert_response :success
  end

  test "should update connection_request" do
    patch :update, id: @connection_request, connection_request: {  }
    assert_redirected_to connection_request_path(assigns(:connection_request))
  end

  test "should destroy connection_request" do
    assert_difference('ConnectionRequest.count', -1) do
      delete :destroy, id: @connection_request
    end

    assert_redirected_to connection_requests_path
  end
end
