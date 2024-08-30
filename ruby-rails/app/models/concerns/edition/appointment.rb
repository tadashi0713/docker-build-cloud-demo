module Edition::Appointment
  extend ActiveSupport::Concern

  included do
    belongs_to :role_appointment

    delegate :role, to: :role_appointment

    validates :role_appointment, presence: true, unless: ->(edition) { edition.can_have_some_invalid_data? || edition.person_override? }
  end

  def is_associated_with_a_minister?
    role_appointment && role.ministerial?
  end

  def person
    if person_override?
      person_override
    else
      role_appointment.person
    end
  end

  def search_index
    if person_override?
      super
    else
      super.merge({
        "people" => [person.slug],
        "roles" => is_associated_with_a_minister? ? [role.slug] : nil,
      }.compact)
    end
  end
end
