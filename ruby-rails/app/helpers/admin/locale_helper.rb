module Admin::LocaleHelper
  def select_locale(attribute, locales, options = {})
    select_tag attribute, options_for_select(options_for_locales(locales)), **options
  end

  def options_for_locales(locales)
    locales.map do |locale|
      locale = Locale.coerce(locale)
      [locale.native_and_english_language_name, locale.code.to_s]
    end
  end
end
