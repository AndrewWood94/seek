require 'test_helper'
require 'jws_online_test_helper'

class JwsOnlineTest < ActionController::TestCase
  tests ModelsController

  include AuthenticatedTestHelper
  include JwsOnlineTestHelper

  test 'simulate button visibility' do
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select '#buttons a[href=?]', simulate_model_path(model, version: 1)

    model = FactoryBot.create(:non_sbml_xml_model, policy: FactoryBot.create(:public_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select '#buttons a[href=?]', simulate_model_path(model, version: 1), count: 0

    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:publicly_viewable_policy))
    get :show, params: { id: model }
    assert_response :success
    assert_select '#buttons a[href=?]', simulate_model_path(model, version: 1), count: 0
  end

  test 'simulate' do
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    assert_difference('model.run_count', 1) do
      get :simulate, params: { id: model.id, version: model.version, constraint_based: '1' }
    end
    assert_response :success
    assert assigns(:simulate_url)

    url = assigns(:simulate_url)
    refute_nil url
    assert url =~ URI.regexp, "simulate url (#{url}) should be a valid url"
    assert_select 'iframe[src=?]', url
  end

  test 'simulate no constraint defined' do
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))
    get :simulate, params: { id: model.id, version: model.version }
    assert_response :success
    refute assigns(:simulate_url)
    assert_select 'input[@type=checkbox]#constraint_based',count: 1
  end

  test 'do not simulate non-jws model' do
    model = FactoryBot.create(:non_sbml_xml_model, policy: FactoryBot.create(:public_policy))

    assert_no_difference('model.run_count') do
      get :simulate, params: { id: model.id, version: model.version, constraint_based: '1' }
    end

    assert_redirected_to root_url
    assert flash[:error].include?('JWS Online-compatible')
  end

  test 'do not log event before simulation is run' do
    model = FactoryBot.create(:teusink_model, policy: FactoryBot.create(:public_policy))

    assert_no_difference('model.run_count') do
      get :simulate, params: { id: model.id, version: model.version } # `constraint_based` param is missing
    end

    assert_response :success
    assert_select 'div', text: /JWS Online needs information.+/
  end
end
