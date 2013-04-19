require 'test_helper'

class BatchPublishingTest < ActionController::TestCase

  tests PeopleController

  fixtures :all

  include AuthenticatedTestHelper

  def setup
    login_as(:aaron)
  end

  test "should have the -Publish all your assets- only one your own profile" do
    get :show, :id => User.current_user.person
    assert_response :success
    assert_select "a[href=?]", batch_publishing_preview_person_path, :text => /Publish all your assets/

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success
    assert_nil flash[:error]

    #not yourself
    a_person = Factory(:person)
    get :show, :id => a_person
    assert_response :success
    assert_select "a", :text => /Publish all your assets/, :count => 0

    get :batch_publishing_preview, :id => a_person.id
    assert_redirected_to :root
    assert_not_nil flash[:error]
  end

  test "get batch_publishing_preview" do
    #bundle of assets that can publish immediately
    publish_immediately_assets = create_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert a.can_publish?,"The asset must be publishable for this test to succeed"
    end
    #bundle of assets that can not publish immediately but can send the publish request to gatekeepers
    gatekeeper_required_assets = create_gatekeeper_required_assets
    gatekeeper_required_assets.each do |a|
      assert a.can_publish?,"The asset must not be publishable for this test to succeed"
      assert a.gatekeeper_required?,"This asset must require gatekeeper's approval for this test to succeed"
    end
    total_asset_count = (publish_immediately_assets + gatekeeper_required_assets).count

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "li.type_and_title", :count=>total_asset_count do
      publish_immediately_assets.each do |a|
        assert_select "a[href=?]",eval("#{a.class.name.underscore}_path(#{a.id})"),:text=>/#{a.title}/
      end
      gatekeeper_required_assets.each do |a|
        assert_select "a[href=?]",eval("#{a.class.name.underscore}_path(#{a.id})"),:text=>/#{a.title}/
      end
      assert_select "li.type_and_title img[src*=?][title=?]",/lock.png/, /Private/, :count => total_asset_count
    end

    assert_select "li.secondary", :text => /Publish/, :count => total_asset_count do
      publish_immediately_assets.each do |a|
        assert_select "input[type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
      end
      gatekeeper_required_assets.each do |a|
        assert_select "input[type='checkbox'][id=?]", "publish_#{a.class.name}_#{a.id}"
      end
    end
  end

  test "do not have not-publishable items in batch_publishing_preview" do
    published_item = Factory(:data_file,
                             :contributor=> User.current_user,
                             :policy => Factory(:public_policy))
    assert !published_item.can_publish?, "This data file must not be publishable for the test to succeed"

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "input[type='checkbox'][id=?]", "publish_#{published_item.class.name}_#{published_item.id}",
                  :count => 0
  end

  test "do not have not_publishable_type item in batch_publishing_preview" do
    item = Factory(:sample, :contributor => User.current_user)
    assert item.can_publish?, "This data file must be publishable for the test to be meaningful"

    get :batch_publishing_preview, :id => User.current_user.person.id
    assert_response :success

    assert_select "input[type='checkbox'][id=?]", "publish_#{item.class.name}_#{item.id}",
                  :count => 0
  end

  test "do publish" do
    #bundle of assets that can publish immediately
    publish_immediately_assets = create_publish_immediately_assets
    publish_immediately_assets.each do |a|
      assert !a.is_published?
      assert a.can_publish?,"The asset must be publishable for this test to succeed"
    end
    #bundle of assets that can not publish immediately but can send the publish request
    gatekeeper_required_assets = create_gatekeeper_required_assets
    gatekeeper_required_assets.each do |a|
      assert a.can_publish?,"The asset must be publishable for this test to succeed"
    end

    total_assets = publish_immediately_assets + gatekeeper_required_assets

    params={:publish=>{}}

    total_assets.each do |asset|
      params[:publish][asset.class.name]||={}
      params[:publish][asset.class.name][asset.id.to_s]="1"
    end

    assert_difference("ResourcePublishLog.count", total_assets.count) do
      assert_emails gatekeeper_required_assets.count do
        post :publish, params.merge(:id=> User.current_user.person.id)
      end
    end
    assert_response :redirect
    assert_nil flash[:error]
    assert_not_nil flash[:notice]

    publish_immediately_assets.each do |a|
      a.reload
      assert a.is_published?
    end
    gatekeeper_required_assets.each do |a|
      a.reload
      assert !a.is_published?
    end
  end

  test "get publish redirected" do
    #This is useful because if you logout it redirects to root.
    #If you just published something, that will do a get request to *Controller#publish
    get :publish, :id=> User.current_user.person.id
    assert_response :redirect
  end

  private

  def create_publish_immediately_assets
    publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
    publishable_types.collect do |klass|
      Factory(klass.name.underscore.to_sym, :contributor => User.current_user)
    end
  end

  def create_gatekeeper_required_assets
    publishable_types = Seek::Util.authorized_types.select {|c| c.first.try(:is_in_isa_publishable?)}
    publishable_types.collect do |klass|
      Factory(klass.name.underscore.to_sym, :contributor => User.current_user, :projects => Factory(:gatekeeper).projects)
    end
  end
end

