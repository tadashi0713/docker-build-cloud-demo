Given(/^there is a user called "([^"]*)"$/) do |name|
  @user = create(:writer, name:)
end

Given(/^there is a user called "([^"]*)" with email address "([^"]*)"$/) do |name, email|
  @user = create(:writer, name:, email:)
end

When(/^I view my own user record$/) do
  visit admin_user_path(@user)
end

Then(/^I can see my user details/) do
  expect(page).to have_selector(".govuk-summary-list__row:nth-child(1) .govuk-summary-list__key", text: "Name")
  expect(page).to have_selector(".govuk-summary-list__row:nth-child(1) .govuk-summary-list__value", text: @user.name)
  expect(page).to have_selector(".govuk-summary-list__row:nth-child(2) .govuk-summary-list__key", text: "Email")
  expect(page).to have_selector(".govuk-summary-list__row:nth-child(2) .govuk-summary-list__value", text: @user.email)
end

Then(/^I cannot change my user details/) do
  expect(page).to_not have_selector("a[href='#{edit_admin_user_path(@user)}']")
  visit edit_admin_user_path(@user)
  expect(page).to_not have_selector("form")
end

When(/^I visit the admin author page for "([^"]*)"$/) do |name|
  user = User.find_by(name:)
  visit admin_author_path(user)
end

Then(/^I should see that I am logged in as a "([^"]*)"$/) do |role|
  visit admin_user_path(@user)

  expect(page).to have_selector(".govuk-summary-list__row:nth-child(3) .govuk-summary-list__key", text: "Role")
  expect(page).to have_selector(".govuk-summary-list__row:nth-child(3) .govuk-summary-list__value", text: role)
end

Then(/^I should see an email address "([^"]*)"$/) do |email_address|
  expect(page).to have_selector(".govuk-grid-column-two-thirds", text: email_address)
end
