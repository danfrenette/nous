# frozen_string_literal: true

module Nous
  Configuration = Data.define(
    :concurrency,
    :match,
    :limit,
    :timeout,
    :debug,
    :keep_query,
    :recursive
  ) do
    def debug? = debug
    def recursive? = recursive
  end
end
