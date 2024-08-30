require "test_helper"

class Admin::PromotionalFeaturesControllerTest < ActionController::TestCase
  setup do
    login_as :writer
    @organisation = create(:executive_office)
  end

  should_be_an_admin_controller

  test "GET :index returns a 404 if the organisation is not allowed promotional" do
    organisation = create(:ministerial_department)

    assert_raise ActiveRecord::RecordNotFound do
      get :index, params: { organisation_id: organisation }
    end
  end

  test "GET :index loads the promotional organisation and renders the index template" do
    create(:promotional_feature, organisation: @organisation)
    get :index, params: { organisation_id: @organisation }

    assert_response :success
    assert_equal @organisation, assigns(:organisation)
    assert_equal @organisation.reload.promotional_features, assigns(:promotional_features)
    assert_template :index
  end

  test "GET :new prepares a promotional feature" do
    get :new, params: { organisation_id: @organisation }

    assert_response :success
    assert_equal @organisation, assigns(:organisation)
    assert assigns(:promotional_feature).is_a?(PromotionalFeature)
  end

  test "POST :create saves the new promotional feature, republishes the organisation to the PublishingApi and redirects to the show page" do
    Whitehall::PublishingApi.expects(:republish_async).once.with(@organisation)

    post :create, params: { organisation_id: @organisation, promotional_feature: { title: "Promotional feature title" } }

    assert promotional_feature = @organisation.reload.promotional_features.last
    assert_equal "Promotional feature title", promotional_feature.title
    assert_redirected_to admin_organisation_promotional_feature_url(@organisation, promotional_feature)
  end

  test "GET :show loads the promotional feature belonging to the organisation" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)
    get :show, params: { organisation_id: @organisation, id: promotional_feature }

    assert_response :success
    assert_template :show
    assert_equal promotional_feature, assigns(:promotional_feature)
  end

  view_test "GET :show displays processing label if item image assets are not available" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)
    promotional_feature_item = build(:promotional_feature_item, promotional_feature:, summary: "Old summary")
    promotional_feature_item.assets = []
    promotional_feature_item.save!

    get :show, params: { organisation_id: @organisation, id: promotional_feature }

    assert_select "span[class='govuk-tag govuk-tag--green']", text: "Processing", count: 1
    assert_match(/The image is being processed. Try refreshing the page./, flash[:notice])
  end

  test "GET :edit loads the promotional feature and renders the template" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)
    get :edit, params: { organisation_id: @organisation, id: promotional_feature }

    assert_response :success
    assert_template :edit
    assert_equal promotional_feature, assigns(:promotional_feature)
  end

  test "PUT :update saves the promotional feature, republishes the organisation to the PublishingApi and redirects to the show page" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)

    Whitehall::PublishingApi.expects(:republish_async).once.with(@organisation)

    put :update, params: { organisation_id: @organisation, id: promotional_feature, promotional_feature: { title: "New title" } }

    assert_redirected_to admin_organisation_promotional_feature_url(@organisation, promotional_feature)
    assert_equal "New title", promotional_feature.reload.title
  end

  test "DELETE :destroy deletes the promotional feature and republishes the organisation to the PublishingApi" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)

    Whitehall::PublishingApi.expects(:republish_async).once.with(@organisation)

    delete :destroy, params: { organisation_id: @organisation, id: promotional_feature }

    assert_redirected_to admin_organisation_promotional_features_url(@organisation)
    assert_not PromotionalFeature.exists?(promotional_feature.id)
    assert_equal "Promotional feature deleted.", flash[:notice]
  end

  test "GET :reorder loads the promotional feature belonging to the organisation" do
    promotional_feature1 = create(:promotional_feature, organisation: @organisation)
    promotional_feature2 = create(:promotional_feature, organisation: @organisation)

    get :reorder, params: { organisation_id: @organisation }

    assert_response :success
    assert_template :reorder
    assert_equal [promotional_feature1, promotional_feature2], assigns(:promotional_features)
  end

  test "GET :reorder redirects to the promotional features index page when the org has less than 2 promotional features" do
    create(:promotional_feature, organisation: @organisation)

    get :reorder, params: { organisation_id: @organisation }

    assert_redirected_to admin_organisation_promotional_features_path(@organisation)
  end

  test "PATCH on :update_order reorders the promotional_features and republishes the organisation" do
    promotional_feature1 = create(:promotional_feature, organisation: @organisation)
    promotional_feature2 = create(:promotional_feature, organisation: @organisation)

    Whitehall::PublishingApi.expects(:republish_async).once.with(@organisation)

    put :update_order, params: {
      organisation_id: @organisation,
      promotional_features: {
        ordering: {
          "#{promotional_feature2.id}": "1",
          "#{promotional_feature1.id}": "2",
        },
      },
    }

    assert_redirected_to admin_organisation_promotional_features_path(@organisation)
    assert_equal "Promotional features reordered successfully", flash[:notice]
    assert_equal [promotional_feature2, promotional_feature1], @organisation.reload.promotional_features
  end

  test "GET :confirm_destroy calls correctly" do
    promotional_feature = create(:promotional_feature, organisation: @organisation)

    get :confirm_destroy, params: { organisation_id: @organisation, id: promotional_feature }

    assert_response :success
    assert_equal promotional_feature, assigns(:promotional_feature)
  end
end
