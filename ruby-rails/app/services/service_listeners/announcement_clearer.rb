module ServiceListeners
  AnnouncementClearer = Struct.new(:edition) do
    def clear!
      if announced_statistics?
        Whitehall::SearchIndex.delete(statistics_announcement)
      end
    end

    def announced_statistics?
      edition.is_a?(Publication) && statistics_announcement.present?
    end

    delegate :statistics_announcement, to: :edition
  end
end
