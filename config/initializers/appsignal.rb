require "open_project/version"
require_relative "../../lib_static/open_project/appsignal"

if OpenProject::Appsignal.enabled?
  require "appsignal"

  Rails.application.configure do |app|
    app.middleware.insert_after(
      ActionDispatch::DebugExceptions,
      Appsignal::Rack::RailsInstrumentation
    )
  end

  Appsignal.configure do |config|
    config.active = true
    config.name = ENV.fetch("APPSIGNAL_NAME")
    config.push_api_key = ENV.fetch("APPSIGNAL_KEY")
    config.revision = OpenProject::VERSION.to_s

    if ENV["APPSIGNAL_DEBUG"] == "true"
      config.log = "stdout"
      config.log_level = "debug"
    end

    config.ignore_actions = [
      "OkComputer::OkComputerController#show",
      "OkComputer::OkComputerController#index",
      "GET::API::V3::Notifications::NotificationsAPI",
      "GET::API::V3::Notifications::NotificationsAPI#/notifications/"
    ]

    config.ignore_errors = [
      "Grape::Exceptions::MethodNotAllowed",
      "ActionController::UnknownFormat",
      "ActiveJob::DeserializationError",
      "Net::SMTPServerBusy"
    ]

    config.ignore_logs = [
      "GET /health_check"
    ]
  end

  # Extend the core log delegator
  handler = OpenProject::Appsignal.method(:exception_handler)
  OpenProject::Logging::LogDelegator.register(:appsignal, handler)

  # Send our logs to appsignal
  if OpenProject::Appsignal.logging_enabled?
    appsignal_logger = Appsignal::Logger.new("rails")
    Rails.logger.broadcast_to(appsignal_logger)
  end

  Appsignal.start
end
