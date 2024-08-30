require "test_helper"

class Admin::PeopleControllerTest < ActionController::TestCase
  setup do
    login_as :writer
  end

  should_be_an_admin_controller

  view_test "new shows form for creating a person" do
    get :new

    assert_select "form[action='#{admin_people_path}']" do
      assert_select "input[name='person[privy_counsellor]'][type=checkbox]"
      assert_select "input[name='person[title]'][type=text]"
      assert_select "input[name='person[forename]'][type=text]"
      assert_select "input[name='person[surname]'][type=text]"
      assert_select "input[name='person[letters]'][type=text]"
      assert_select "input[name='person[image_attributes][file]'][type=file]"
      assert_select "textarea[name='person[biography]']"
    end
  end

  view_test "creating with invalid data shows errors" do
    post :create, params: { person: { title: "", forename: "", surname: "", letters: "" } }

    assert_select ".govuk-error-summary"
  end

  test "creating with valid data creates a new person" do
    attributes = attributes_for(:person, title: "person-title", forename: "person-forename", surname: "person-surname", letters: "person-letters", biography: "person-biography")

    post :create, params: { person: attributes }

    assert_not_nil person = Person.last
    assert_equal attributes[:title], person.title
    assert_equal attributes[:forename], person.forename
    assert_equal attributes[:surname], person.surname
    assert_equal attributes[:letters], person.letters
    assert_equal attributes[:biography], person.biography
    assert_equal "\"#{person.name}\" created.", flash[:notice]
  end

  test "creating with valid data redirects to the index" do
    post :create, params: { person: attributes_for(:person) }

    assert_redirected_to admin_person_url(Person.last)
  end

  test "creating allows attachment of an image" do
    attributes = attributes_for(:person)
    attributes[:image_attributes] = { file: upload_fixture("minister-of-funk.960x640.jpg", "image/jpg") }

    post :create, params: { person: attributes }

    assert_equal "minister-of-funk.960x640.jpg", Person.last.image.filename
  end

  test "GET on :show assigns the person and renders the show page" do
    person = create(:person)
    get :show, params: { id: person }

    assert_equal person, assigns(:person)
    assert_response :success
    assert_template :show
  end

  view_test "GET on :show displays the users information in a summary list component and renders delete and edit link" do
    person = create(
      :person,
      forename: "Dave",
      surname: "David",
      privy_counsellor: true,
      title: "Mr",
      letters: "OBE",
      biography: "He is the PM.",
    )

    get :show, params: { id: person }

    assert_select ".govuk-summary-list__row:nth-child(1) .govuk-summary-list__key", text: "Rt Hon"
    assert_select ".govuk-summary-list__row:nth-child(1) .govuk-summary-list__value", text: "Yes"
    assert_select ".govuk-summary-list__row:nth-child(2) .govuk-summary-list__key", text: "Title"
    assert_select ".govuk-summary-list__row:nth-child(2) .govuk-summary-list__value", text: "Mr"
    assert_select ".govuk-summary-list__row:nth-child(3) .govuk-summary-list__key", text: "Forename"
    assert_select ".govuk-summary-list__row:nth-child(3) .govuk-summary-list__value", text: "Dave"
    assert_select ".govuk-summary-list__row:nth-child(4) .govuk-summary-list__key", text: "Surname"
    assert_select ".govuk-summary-list__row:nth-child(4) .govuk-summary-list__value", text: "David"
    assert_select ".govuk-summary-list__row:nth-child(5) .govuk-summary-list__key", text: "Letters"
    assert_select ".govuk-summary-list__row:nth-child(5) .govuk-summary-list__value", text: "OBE"
    assert_select ".govuk-summary-list__row:nth-child(6) .govuk-summary-list__key", text: "Biography"
    assert_select ".govuk-summary-list__row:nth-child(6) .govuk-summary-list__value", text: "He is the PM."
    assert_select ".govuk-summary-list__actions-list a[href='#{edit_admin_person_path(person)}']", text: /Edit Details/
    assert_select ".govuk-summary-list__actions-list a[href='#{confirm_destroy_admin_person_path(person)}']", text: "Delete Details"
  end

  view_test "GET on :show displays the image row with a processing label if image assets are still uploading" do
    person = build(:person, :with_image, forename: "Forename", surname: "Surname")
    person.image.assets = []
    person.save!

    get :show, params: { id: person }

    assert_select ".govuk-summary-list__row .govuk-summary-list__key", text: "Image"
    assert_select "span[class='govuk-tag govuk-tag--green']", text: "Processing", count: 1
    assert_match(/The image is being processed. Try refreshing the page./, flash[:notice])
  end

  view_test "editing shows form for editing a person" do
    person = create(:person, :with_image)
    get :edit, params: { id: person }

    assert_select "form[action='#{admin_person_path}']" do
      assert_select "input[name='person[title]'][type=text]"
      assert_select "input[name='person[forename]'][type=text]"
      assert_select "input[name='person[surname]'][type=text]"
      assert_select "input[name='person[letters]'][type=text]"
      assert_select "input[name='person[image_attributes][file]'][type=file]"
      assert_select "textarea[name='person[biography]']"
    end
  end

  view_test "editing shows existing image" do
    person = create(:person, :with_image)
    get :edit, params: { id: person }

    assert_select "img[src='#{person.image.url}']"
  end

  view_test "editing shows processing label if image assets are not available" do
    person = build(:person, :with_image)
    person.image.assets = []
    person.save!

    get :edit, params: { id: person }

    assert_select "span[class='govuk-tag govuk-tag--green']", text: "Processing", count: 1
  end

  view_test "updating with invalid data shows errors" do
    person = create(:person)

    put :update, params: { id: person.id, person: { title: "", forename: "", surname: "", letters: "" } }

    assert_select ".govuk-error-summary"
  end

  test "updating with valid data redirects to the index" do
    person = create(:person)

    put :update, params: { id: person.id, person: attributes_for(:person) }

    assert_redirected_to admin_person_url(person)
  end

  test "PUT :update saves changes to the person and image" do
    person = create(:person, :with_image)
    image = person.image

    put :update, params: {
      id: person.id,
      person: attributes_for(:person).merge(
        image_attributes: {
          id: image.id,
          file: upload_fixture("images/960x640_jpeg.jpg"),
        },
      ),
    }

    assert_response :redirect

    assert_equal image.id, person.reload.image.id
    assert_equal "960x640_jpeg.jpg", person.reload.image.filename
  end

  test "PUT :update does not republish the past prime ministers page if the person has not been the prime minister" do
    person = create(:person)

    PresentPageToPublishingApi
    .expects(:new)
    .never

    Sidekiq::Testing.inline! do
      put :update, params: {
        id: person.id,
        person: attributes_for(:person),
      }
    end
  end

  test "should be able to destroy a destroyable person" do
    person = create(:person, forename: "Dave")
    delete :destroy, params: { id: person.id }

    assert_response :redirect
    assert_equal %("Dave" destroyed.), flash[:notice]
  end

  test "destroying a person which has an appointment" do
    person = create(:person)
    create(:role_appointment, person:)

    delete :destroy, params: { id: person.id }
    assert_equal "Cannot destroy a person with appointments", flash[:alert]
  end

  test "should be able to visit the confirm destroy page for a destroyable person" do
    person = create(:person, forename: "Dave")
    get :confirm_destroy, params: { id: person.id }

    assert_response :success
    assert_equal person, assigns(:person)
  end

  test "visiting confirm destroy for a person which has an appointment" do
    person = create(:person)
    create(:role_appointment, person:)

    get :confirm_destroy, params: { id: person.id }

    assert_redirected_to admin_person_url(person)
    assert_equal "Cannot destroy a person with appointments", flash[:alert]
  end

  test "lists people in alphabetical name order" do
    create(:person, forename: "B")
    create(:person, forename: "A")
    create(:person, forename: "C")

    get :index

    assert_equal %w[A B C], assigns(:people).map(&:name)
  end

  view_test "lists people displaying the first bit of their biography" do
    create(:person, title: "Colonel", surname: "Hathi", biography: %(Hathi is head of the elephant troop. He is one of the oldest animals of the jungle and represents order, dignity and obedience to the Law of the Jungle. In "How Fear Came", he tells the jungle animals' creation myth and describes Tha, the Creator.))

    get :index

    assert_select ".govuk-table__cell", text: %r{^Hathi is head of the elephant troop}
  end

  test "GET on :edit denied if not a vip-editor" do
    pm = create(:pm)

    login_as :writer
    get :edit, params: { id: pm.slug }
    assert_response :forbidden
  end

  test "PUT on :update denied if not a vip-editor" do
    pm = create(:pm)

    login_as :writer
    put :update, params: { id: pm.slug }
    assert_response :forbidden
  end

  test "DELETE on :destroy denied if not a vip-editor" do
    pm = create(:pm)

    login_as :writer
    delete :destroy, params: { id: pm.slug }
    assert_response :forbidden
  end

  %i[vip_editor gds_admin].each do |permission|
    test "GET on :edit allowed if a #{permission}" do
      pm = create(:pm)

      login_as :vip_editor
      get :edit, params: { id: pm.slug }
      assert_response :success
    end

    test "PUT on :update allowed if a #{permission}" do
      pm = create(:pm)

      login_as :vip_editor
      put :update, params: { id: pm.slug, person: { title: "", forename: "Aronnax", surname: "", letters: "" } }

      assert_redirected_to admin_person_url(pm)
      assert_equal %("Aronnax" saved.), flash[:notice]
    end
  end

  test "GET on :reorder_role_appointments allowed if a GDS editor" do
    person = create(:person)
    role_appointment1 = create(:role_appointment, person:)
    role_appointment2 = create(:role_appointment, person:)
    role_appointment4 = create(:role_appointment, person:)
    role_appointment5 = create(:role_appointment, person:)

    login_as :gds_admin
    get :reorder_role_appointments, params: { id: person.id }

    assert_equal [role_appointment1, role_appointment2, role_appointment4, role_appointment5], assigns(:role_appointments)
    assert_response :success
  end

  test "GET on :reorder_role_appointments not allowed if not a GDS editor" do
    person = create(:person)

    get :reorder_role_appointments, params: { id: person.id }
    assert_response :forbidden
  end

  test "PATCH on :update_order_role_appointments allowed and reorders RoleAppointments if a GDS Editor" do
    person = create(:person)
    role_appointment1 = create(:role_appointment, person:)
    role_appointment2 = create(:role_appointment, person:)
    role_appointment3 = create(:role_appointment, person:, started_at: 2.years.ago, ended_at: 1.year.ago)
    role_appointment4 = create(:role_appointment, person:)
    role_appointment5 = create(:role_appointment, person:)

    login_as :gds_admin

    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment1.organisations.first)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment2.organisations.first)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment4.organisations.first)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment5.organisations.first)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment1.role)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment2.role)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment4.role)
    Whitehall::PublishingApi.expects(:republish_async).with(role_appointment5.role)

    put :update_order_role_appointments, params: {
      id: person.id,
      role_appointments: {
        ordering: {
          "#{role_appointment5.id}": "1",
          "#{role_appointment4.id}": "2",
          "#{role_appointment2.id}": "3",
          "#{role_appointment1.id}": "4",
        },
      },
    }

    assert_equal 1, role_appointment5.reload.ordering
    assert_equal 2, role_appointment4.reload.ordering
    assert_equal 3, role_appointment3.reload.ordering
    assert_equal 4, role_appointment2.reload.ordering
    assert_equal 5, role_appointment1.reload.ordering
    assert_redirected_to admin_person_url(person)
    assert_equal "Role appointments reordered successfully", flash[:notice]
  end

  test "PATCH on :update_order_role_appointments not allowed if not a GDS Editor" do
    person = create(:person)

    put :update_order_role_appointments, params: {
      id: person.id,
    }

    assert_response :forbidden
  end

  test "POST: create - discards image cache if file is present" do
    filename = "big-cheese.960x640.jpg"
    cached_image = build(:featured_image_data)

    Services.asset_manager.stubs(:create_asset).returns("id" => "http://asset-manager/assets/asset_manager_id", "name" => filename)
    AssetManagerCreateAssetWorker.expects(:perform_async).with(regexp_matches(/minister-of-funk.960x640/), anything, anything, anything, anything, anything).never
    AssetManagerCreateAssetWorker.expects(:perform_async).with(regexp_matches(/#{filename}/), anything, anything, anything, anything, anything).times(7)

    post :create,
         params: {
           person: {
             forename: "George II",
             image_attributes: {
               file: upload_fixture(filename, "image/png"),
               file_cache: cached_image.file_cache,
             },
           },
         }
  end

  test "PUT: update - discards image cache if file is present" do
    person = FactoryBot.create(:person, :with_image)
    image = person.image

    replacement_filename = "example_fatality_notice_image.jpg"
    cached_filename = "big-cheese.960x640.jpg"
    cached_image = build(:featured_image_data, file: upload_fixture(cached_filename, "image/png"))

    Services.asset_manager.stubs(:create_asset).returns("id" => "http://asset-manager/assets/asset_manager_id", "name" => replacement_filename)
    AssetManagerCreateAssetWorker.expects(:perform_async).with(regexp_matches(/#{replacement_filename}/), anything, anything, anything, anything, anything).times(7)
    AssetManagerCreateAssetWorker.expects(:perform_async).with(regexp_matches(/#{cached_filename}/), anything, anything, anything, anything, anything).never

    put :update,
        params: {
          id: person.id,
          person: {
            image_attributes: {
              id: image.id,
              file: upload_fixture(replacement_filename, "image/png"),
              file_cache: cached_image.file_cache,
            },
          },
        }
  end
end
