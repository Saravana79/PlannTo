require 'test_helper'

class ItemrelationshipsControllerTest < ActionController::TestCase
  setup do
    @itemrelationship = itemrelationships(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:itemrelationships)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create itemrelationship" do
    assert_difference('Itemrelationship.count') do
      post :create, itemrelationship: @itemrelationship.attributes
    end

    assert_redirected_to itemrelationship_path(assigns(:itemrelationship))
  end

  test "should show itemrelationship" do
    get :show, id: @itemrelationship.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @itemrelationship.to_param
    assert_response :success
  end

  test "should update itemrelationship" do
    put :update, id: @itemrelationship.to_param, itemrelationship: @itemrelationship.attributes
    assert_redirected_to itemrelationship_path(assigns(:itemrelationship))
  end

  test "should destroy itemrelationship" do
    assert_difference('Itemrelationship.count', -1) do
      delete :destroy, id: @itemrelationship.to_param
    end

    assert_redirected_to itemrelationships_path
  end
end
