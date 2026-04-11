# frozen_string_literal: true

module Nous
  FetchResult = Data.define(:pages, :failures, :total_requested) do
    def succeeded
      pages.length
    end

    def failed
      failures.length
    end

    def all_succeeded?
      failures.empty?
    end

    def any_succeeded?
      pages.any?
    end
  end
end
