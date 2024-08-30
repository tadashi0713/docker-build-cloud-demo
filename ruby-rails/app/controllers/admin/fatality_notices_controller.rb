class Admin::FatalityNoticesController < Admin::EditionsController
  before_action :require_fatality_handling_permission!, except: :show
  before_action :build_fatality_notice_casualties, only: %i[new edit]

private

  def edition_class
    FatalityNotice
  end

  def build_fatality_notice_casualties
    @edition.fatality_notice_casualties.build unless @edition.fatality_notice_casualties.any?
  end
end
