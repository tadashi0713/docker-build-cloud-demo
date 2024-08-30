Feature: Unpublishing published documents
  As a managing editor
  I want to be able to revert published documents back to the draft state
  So that I can remove documents from the site that were published in error

  Background:
    Given I am a managing editor

  @not-quite-as-fake-search
  Scenario: Unpublishing a published document
    Given a published document "Published by accident" exists
    When I unpublish the document because it was published in error
    Then there should be an editorial remark recording the fact that the document was unpublished
    And there should be an unpublishing explanation of "This page should never have existed" and a reason of "Published in error"

  Scenario: Unpublishing a document and redirecting
    Given a published document "Published by accident" exists
    When I unpublish the document and ask for a redirect to "https://www.test.gov.uk/example"
    Then the unpublishing should redirect to "https://www.test.gov.uk/example"

  Scenario: Consolidating a document into another GOV.UK page
    Given there is a published document that is a duplicate of another page
    When I unpublish the duplicate, marking it as consolidated into the other page
    Then the unpublishing should redirect to the existing edition

  Scenario: Withdraw a document that is no longer current
    Given a published publication "Shaving kits for all" exists
    When I withdraw the publication with the explanation "Policy change"
    Then there should be an unpublishing explanation of "Policy change" and a reason of "No longer current government policy/activity"
    And the withdrawal date should be today

  Scenario: Change the public explanation for a withdrawn document
    Given a published publication "Shaving kits for all" exists
    When I withdraw the publication with the explanation "Policy change"
    When I edit the public explanation for withdrawal to "The policy has changed"
    Then there should be an unpublishing explanation of "The policy has changed" and a reason of "No longer current government policy/activity"

  Scenario: Withdraw a document using a previous withdrawal date & explanation
    Given a published publication "Free ice creams" exists
    And the publication was withdrawn on 01/12/2020 with the explanation "It's too cold for ice cream"
    And it was subsequently unwithdrawn
    When I go to withdraw the publication again
    And I choose to reuse the withdrawal from 01/12/2020
    Then there should be an unpublishing explanation of "It's too cold for ice cream" and a reason of "No longer current government policy/activity"
    And the withdrawal date should be 01/12/2020
