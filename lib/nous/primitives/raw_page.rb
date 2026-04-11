# frozen_string_literal: true

module Nous
  RawPage = Data.define(:url, :pathname, :html, :requested_url, :content_type)
end
