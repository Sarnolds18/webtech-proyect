module Api
  module V1
    # The public JSON API. It inherits from ActionController::API, not ApplicationController, so
    # sessions, Pundit and `allow_browser` do not apply: everything here is public and read-only,
    # and only public data is rendered.
    class BaseController < ActionController::API
      class InvalidParameter < StandardError
        attr_reader :parameter

        def initialize(parameter, message)
          @parameter = parameter.to_s
          super(message)
        end
      end

      rescue_from ActiveRecord::RecordNotFound do
        render_error :not_found, "not_found", "The resource does not exist or is not public."
      end

      rescue_from InvalidParameter do |error|
        render_error :bad_request, "invalid_parameter", error.message, parameter: error.parameter
      end

      def route_not_found
        render_error :not_found, "not_found", "Unknown API endpoint."
      end

      private

      # Every error has the same shape: { "error": { "status", "code", "message", ... } }.
      def render_error(status, code, message, **details)
        render json: { error: { status: Rack::Utils.status_code(status), code:, message:, **details } }, status:
      end
    end
  end
end
