require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  include Devise::TestHelpers

  test 'should get show' do
    object = products(:camera)
    get :show, id: object.id
    assert_response :success

    object = products(:camera)
    get :show, slug: object.slug
    assert_response :success
  end

  test 'should add to shopping cart' do
    login_customer

    object = products(:camera)

    get :add_to_shopping_cart, id: object.id
    assert_response 302

    get :delete_from_shopping_cart, id: object.id
    assert_response 302

    get :add_to_shopping_cart, id: object.id
    assert_response 302

    object = products(:lens_canon)
    get :add_to_shopping_cart, id: object.id
    assert_response 302
  end
end
