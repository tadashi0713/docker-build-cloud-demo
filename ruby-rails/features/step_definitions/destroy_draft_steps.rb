When("I discard the draft publication") do
  @publication = Publication.last
  visit confirm_destroy_admin_edition_path(@publication)
  click_on "Delete"
end

Then("the publication is deleted") do
  @publication = Publication.last
  expect(@publication).to be_nil
end
