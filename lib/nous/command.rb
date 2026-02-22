# frozen_string_literal: true

module Nous
  class Command
    class CommandError < StandardError; end

    class Result
      attr_reader :payload, :error, :metadata

      def initialize(success:, payload: nil, error: nil, metadata: {})
        @success = success
        @payload = payload
        @error = error
        @metadata = metadata
      end

      def success?
        @success
      end

      def failure?
        !@success
      end
    end

    def self.call(...)
      command = new(...)
      command.call
    rescue => e
      return command.failure(CommandError.new("unexpected: #{e.message}")) if command

      Result.new(success: false, error: e)
    end

    def success(payload:, metadata: {})
      Result.new(success: true, payload:, metadata:)
    end

    def failure(error, metadata: {})
      Result.new(success: false, error:, metadata:)
    end
  end
end
