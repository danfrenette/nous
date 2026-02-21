# frozen_string_literal: true

require "reverse_markdown"

module Nous
  class Converter < Command
    class Error < Command::Error; end

    def initialize(html:)
      @html = html
    end

    def call
      markdown = ReverseMarkdown.convert(html, github_flavored: true).strip
      success(payload: markdown)
    end

    private

    attr_reader :html
  end
end
