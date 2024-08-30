require "test_helper"

class PublishingApi::WorldwideOrganisationPresenterTest < ActiveSupport::TestCase
  def present(...)
    PublishingApi::WorldwideOrganisationPresenter.new(...)
  end

  test "presents a Worldwide Organisation ready for adding to the publishing API" do
    worldwide_org = create(:worldwide_organisation,
                           :with_role,
                           :with_social_media_account,
                           :with_main_office,
                           :with_home_page_offices,
                           :with_pages,
                           :with_default_news_image,
                           analytics_identifier: "WO123")

    primary_role = create(:ambassador_role)
    ambassador = create(:person)
    create(:ambassador_role_appointment, role: primary_role, person: ambassador)
    worldwide_org.roles << primary_role

    secondary_role = create(:deputy_head_of_mission_role)
    deputy_head_of_mission = create(:person)
    create(:deputy_head_of_mission_role_appointment, role: secondary_role, person: deputy_head_of_mission)
    worldwide_org.roles << secondary_role

    former_role = create(:ambassador_role)
    create(:ambassador_role_appointment, :ended, role: former_role, person: deputy_head_of_mission)
    worldwide_org.roles << former_role

    public_path = worldwide_org.public_path

    expected_hash = {
      auth_bypass_ids: [worldwide_org.auth_bypass_id],
      base_path: public_path,
      title: worldwide_org.title,
      schema_name: "worldwide_organisation",
      document_type: "worldwide_organisation",
      locale: "en",
      publishing_app: Whitehall::PublishingApp::WHITEHALL,
      rendering_app: Whitehall::RenderingApp::GOVERNMENT_FRONTEND,
      public_updated_at: worldwide_org.updated_at,
      routes: [{ path: public_path, type: "exact" }],
      redirects: [],
      description: worldwide_org.summary,
      details: {
        body: "<div class=\"govspeak\"><p>Information about the organisation with <em>italics</em>.</p>\n</div>",
        default_news_image: {
          url: worldwide_org.default_news_image.file.url(:s300),
          high_resolution_url: worldwide_org.default_news_image.file.url(:s960),
        },
        logo: {
          crest: "single-identity",
          formatted_title: "Worldwide<br/>organisation<br/>title",
        },
        ordered_corporate_information_pages: [
          {
            content_id: worldwide_org.pages[0].content_id,
            title: "Complaints procedure",
          },
          {
            content_id: worldwide_org.pages[3].content_id,
            title: "Working for Worldwide organisation title",
          },
        ],
        secondary_corporate_information_pages: "Read about the types of information we routinely publish in our <a class=\"govuk-link\" href=\"/world/organisations/worldwide-organisation-title/about/publication-scheme\">Publication scheme</a>. Find out about our commitment to <a class=\"govuk-link\" href=\"/world/organisations/worldwide-organisation-title/about/welsh-language-scheme\">publishing in Welsh</a>. Our <a class=\"govuk-link\" href=\"/world/organisations/worldwide-organisation-title/about/personal-information-charter\">Personal information charter</a> explains how we treat your personal information.",
        office_contact_associations: [
          {
            office_content_id: worldwide_org.reload.main_office.content_id,
            contact_content_id: worldwide_org.reload.main_office.contact.content_id,
          },
          {
            office_content_id: worldwide_org.reload.home_page_offices.first.content_id,
            contact_content_id: worldwide_org.reload.home_page_offices.first.contact.content_id,
          },
        ],
        people_role_associations: [
          {
            person_content_id: ambassador.content_id,
            role_appointments: [
              {
                role_appointment_content_id: ambassador.roles.first.current_role_appointment.content_id,
                role_content_id: ambassador.roles.first.current_role_appointment.role.content_id,
              },
            ],
          },
          {
            person_content_id: deputy_head_of_mission.content_id,
            role_appointments: [
              {
                role_appointment_content_id: deputy_head_of_mission.roles.first.current_role_appointment.content_id,
                role_content_id: deputy_head_of_mission.roles.first.current_role_appointment.role.content_id,
              },
            ],
          },
        ],
        social_media_links: [
          {
            href: worldwide_org.social_media_accounts.first.url,
            service_type: worldwide_org.social_media_accounts.first.service_name.parameterize,
            title: worldwide_org.social_media_accounts.first.display_name,
          },
        ],
        world_location_names: [
          {
            content_id: worldwide_org.world_locations.first.content_id,
            name: worldwide_org.world_locations.first.name,
          },
        ],
      },
      links: {
        contacts: [
          worldwide_org.reload.main_office.contact.content_id,
          worldwide_org.reload.home_page_offices.first.contact.content_id,
        ],
        main_office: [
          worldwide_org.reload.main_office.content_id,
        ],
        home_page_offices: [
          worldwide_org.reload.home_page_offices.first.content_id,
        ],
        office_staff: worldwide_org.office_staff_roles.map(&:current_person).map(&:content_id),
        primary_role_person: [
          ambassador.content_id,
        ],
        role_appointments: [
          ambassador.roles.first.current_role_appointment.content_id, deputy_head_of_mission.roles.first.current_role_appointment.content_id
        ],
        roles: worldwide_org.roles.map(&:content_id),
        secondary_role_person: [
          deputy_head_of_mission.content_id,
        ],
        sponsoring_organisations: worldwide_org.organisations.map(&:content_id),
        world_locations: worldwide_org.world_locations.map(&:content_id),
        corporate_information_pages: worldwide_org.pages.map(&:content_id).sort,
      },
      analytics_identifier: "WO123",
      update_type: "major",
    }

    expected_links = {}

    presented_item = present(worldwide_org)

    assert_equal expected_hash, presented_item.content
    assert_equal "major", presented_item.update_type
    assert_equal worldwide_org.content_id, presented_item.content_id

    assert_valid_against_publisher_schema(presented_item.content, "worldwide_organisation")

    assert_equal expected_links, presented_item.links
    assert_valid_against_links_schema({ links: presented_item.links }, "worldwide_organisation")
  end

  test "uses the title for the formatted_title when the locale is not en" do
    I18n.with_locale(:it) do
      worldwide_org = create(:worldwide_organisation, title: "Consolato Generale Britannico Milano")

      presented_item = present(worldwide_org)

      assert_equal "Consolato Generale Britannico Milano", presented_item.content.dig(:details, :logo, :formatted_title)
    end
  end

  test "uses the title for the formatted_title when the the logo_formatted_name is absent" do
    worldwide_org = create(:worldwide_organisation, logo_formatted_name: nil)

    presented_item = present(worldwide_org)

    assert_equal "Worldwide organisation title", presented_item.content.dig(:details, :logo, :formatted_title)
  end

  test "includes an empty array when there are no contacts" do
    worldwide_org = create(:worldwide_organisation)

    presented_item = present(worldwide_org)

    assert_equal [], presented_item.content.dig(:links, :contacts)
  end

  test "maintains the user specified order of lead organisations" do
    lead_organisation_1 = create(:organisation)
    lead_organisation_2 = create(:organisation)

    worldwide_org = create(:worldwide_organisation, lead_organisations: [lead_organisation_2, lead_organisation_1])

    presented_item = present(worldwide_org)

    assert_equal [lead_organisation_2.content_id, lead_organisation_1.content_id], presented_item.content.dig(:links, :sponsoring_organisations)
  end

  test "is valid against the schema when there is no default_news_image" do
    worldwide_organisation = create(:worldwide_organisation, default_news_image: nil)

    presented_item = present(worldwide_organisation)

    assert_valid_against_publisher_schema(presented_item.content, "worldwide_organisation")
  end

  test "default_news_image is not present when there is no image" do
    worldwide_organisation = create(:worldwide_organisation, default_news_image: nil)
    presented_item = present(worldwide_organisation)

    assert_not presented_item.content[:details].key? :default_news_image
  end

  test "default_news_image is not present when variants are not uploaded" do
    featured_image = build(:featured_image_data)
    featured_image.assets.destroy_all
    worldwide_organisation = create(:worldwide_organisation, default_news_image: featured_image)
    presented_item = present(worldwide_organisation)

    assert_not presented_item.content[:details].key? :default_news_image
  end

  test "does not convert an absent body to govspeak" do
    worldwide_org = create(:worldwide_organisation)

    # rubocop:disable Rails/SkipsModelValidations
    worldwide_org.update_attribute(:body, nil)
    # rubocop:enable Rails/SkipsModelValidations

    presented_item = present(worldwide_org.reload)

    assert_equal "", presented_item.content.dig(:details, :body)
  end

  test "does not convert an empty body to govspeak" do
    worldwide_org = create(:worldwide_organisation)

    # rubocop:disable Rails/SkipsModelValidations
    worldwide_org.update_attribute(:body, "")
    # rubocop:enable Rails/SkipsModelValidations

    presented_item = present(worldwide_org.reload)

    assert_equal "", presented_item.content.dig(:details, :body)
  end
end
