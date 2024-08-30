require "test_helper"

class Admin::HistoricalAccountsControllerTest < ActionController::TestCase
  setup do
    login_as :writer
    @person = create(:person)
    @role = create(:historic_role)
  end

  test "GET on :index assigns the person, their historical accounts and renders the :index template" do
    historical_account = create(:historical_account, person: @person, role: @role)
    get :index, params: { person_id: @person }

    assert_response :success
    assert_template :index
    assert_equal @person, assigns(:person)
    assert_equal historical_account, assigns(:historical_account)
  end

  view_test "GET on :index should display a historical account's details and prevent creation of a second historical account" do
    create(:historic_role_appointment, person: @person, role: @role)
    historical_account = create(:historical_account, person: @person, role: @role)

    get :index, params: { person_id: @person }

    assert_select ".govuk-table__cell a:nth-child(1)[href='#{historical_account.public_url}']", text: "View #{@role.name}"
    assert_select ".govuk-table__cell a:nth-child(2)[href='#{edit_admin_person_historical_account_path(@person, historical_account)}']", text: "Edit #{@role.name}"
    assert_select ".govuk-table__cell a:nth-child(3)[href='#{confirm_destroy_admin_person_historical_account_path(@person, historical_account)}']", text: "Delete #{@role.name}"
    assert_select ".govuk-button", text: "Create historical account", count: 0
  end

  view_test "GET on :index should show Create historical accounts button when historical account is not created" do
    create(:historic_role_appointment, person: @person, role: @role)
    get :index, params: { person_id: @person }

    assert_select(".govuk-button", text: "Create historical account", count: 1)
  end
  test "GET on :new assigns the person, a fresh historical account and renders the :new template" do
    get :new, params: { person_id: @person }

    assert_response :success
    assert_template :new
    assert_equal @person, assigns(:person)
    assert assigns(:historical_account).is_a?(HistoricalAccount)
    assert assigns(:historical_account).new_record?
  end

  test "POST on :create saves the historical account and redirects to the historical accounts index" do
    historical_account_params = {
      summary: "Summary",
      body: "Body",
      political_party_ids: [PoliticalParty::Labour.id],
      interesting_facts: "Stuff",
      major_acts: "Mo Stuff",
    }

    post :create, params: { person_id: @person, historical_account: historical_account_params }

    assert_redirected_to admin_person_historical_accounts_path(@person)

    historical_account = @person.historical_account
    assert_equal @role, historical_account.role
    assert_equal "Summary", historical_account.summary
    assert_equal "Body", historical_account.body
    assert_equal [PoliticalParty::Labour], historical_account.political_parties
    assert_equal "Stuff", historical_account.interesting_facts
    assert_equal "Mo Stuff", historical_account.major_acts
  end

  test "POST on :create with invalid paramters re-renders :new template" do
    post :create, params: { person_id: @person, historical_account: { summary: "Only summary" } }

    assert_template :new
    assert_equal "Only summary", assigns(:historical_account).summary
  end

  test "GET on :edit loads the historical account and renders the :edit template" do
    @historical_account = create(:historical_account, person: @person, role: @role)
    get :edit, params: { person_id: @person, id: @historical_account }

    assert_response :success
    assert_template :edit
    assert_equal @person, assigns(:person)
    assert_equal @historical_account, assigns(:historical_account)
  end

  test "PUT on :update updates the details of the historical account" do
    @historical_account = create(:historical_account, person: @person, role: @role)
    put :update, params: { person_id: @person, id: @historical_account, historical_account: { summary: "New summary" } }

    assert_redirected_to admin_person_historical_accounts_path(@person)
    assert_equal "New summary", @historical_account.reload.summary
  end

  test "PUT on :update with invalid paramters re-renders the :edit template" do
    @historical_account = create(:historical_account, person: @person, role: @role)
    summary_before = @historical_account.summary
    put :update, params: { person_id: @person, id: @historical_account, historical_account: { summary: "" } }
    assert_template :edit
    assert_equal summary_before, @historical_account.reload.summary
    assert_equal "", assigns(:historical_account).summary
  end

  test "Delete on :destroy destroys the historical account" do
    @historical_account = create(:historical_account, person: @person, role: @role)
    delete :destroy, params: { person_id: @person, id: @historical_account }
    assert_not HistoricalAccount.exists?(@historical_account.id)
    assert_redirected_to admin_person_historical_accounts_path(@person)
  end
end
