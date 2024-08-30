When(/^I draft a new statistical data set "([^"]*)" for organisation "([^"]*)"$/) do |title, organisation_name|
  begin_drafting_statistical_data_set(title:)
  set_lead_organisation_on_document(Organisation.find_by(name: organisation_name))
  click_button "Save and go to document summary"
end
