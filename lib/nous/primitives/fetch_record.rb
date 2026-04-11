# frozen_string_literal: true

module Nous
  FetchRecord = Data.define(
    :requested_url,
    :final_url,
    :pathname,
    :html,
    :content_type,
    :ok,
    :error,
    :redirected
  ) do
    def initialize(
      requested_url:,
      pathname:, final_url: nil,
      html: nil,
      content_type: nil,
      ok: true,
      error: nil,
      redirected: false
    )
      super
    end
  end
end
