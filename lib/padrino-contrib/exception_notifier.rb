##
# This is an exception notifier for Padrino::Application with
# redmine bonus feature.
#
# ==== Usage
#
#   class MyApp < Padrino::Application
#     register Padrino::Contrib::ExceptionNotifier
#     set :exceptions_from,    "errors@localhost.local"
#     set :exceptions_to,      "foo@bar.local"
#     set :exceptions_page,    :errors # => views/errors.haml/erb
#     set :redmine, :project => "My Bugs", :tracker => "Bugs", :priority => "High"
#     # Uncomment this for test in development
#     # disable :raise_errors
#     # disable :show_exceptions
#   end
#
module Padrino
  module Contrib
    module ExceptionNotifier

      def self.registered(app)
        app.set :exceptions_subject, "Exception" unless app.respond_to?(:exceptions_subject)
        app.set :exceptions_to,      "errors@localhost.local" unless app.respond_to?(:exceptions_to)
        app.set :exceptions_from,    "foo@bar.local" unless app.respond_to?(:exceptions_from)
        app.set :exceptions_layout,  :layout unless app.respond_to?(:exceptions_layout)
        app.set :redmine, {} unless app.respond_to?(:redmine)
        app.error 500 do
          boom  = env['sinatra.error']
          body  = ["#{boom.class} - #{boom.message}:", *boom.backtrace].join("\n  ")
          body += "\n\n---Env:\n"
          env.each { |k,v| body += "\n#{k}: #{v}" }
          body += "\n\n---Params:\n"
          params.each { |k,v| body += "\n#{k.inspect} => #{v.inspect}" }
          logger.error body
          settings.redmine.each { |k,v| body += "\n#{k.to_s.capitalize}: #{v}" }
          app.email do
            subject "[#{app.exceptions_subject}] #{boom.class} - #{boom.message}"
            to app.exceptions_to
            from app.exceptions_from
            body body
          end
          response.status = 500
          content_type 'text/html', :charset => "utf-8"
          render settings.exceptions_page, :layout => settings.exceptions_layout
        end
        app.error 404 do
          response.status = 404
          content_type 'text/html', :charset => "utf-8"
          render settings.exceptions_page, :layout => settings.exceptions_layout
        end
      end # self.registered
    end # ExceptionNotifier
  end # Contrib
end # Padrino
