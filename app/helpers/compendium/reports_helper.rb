module Compendium
  module ReportsHelper
    def expose(*args)
      klass = args.pop if args.last.is_a?(Class)
      klass ||= "Compendium::Presenters::#{args.first.class}".constantize
      presenter = klass.new(self, *(args.empty? ? [nil] : args))
      yield presenter if block_given?
      presenter
    end

    def render_report_setup(assigns)
      render file: "#{Compendium::Engine.root}/app/views/compendium/reports/setup", locals: assigns
    end

    def render_if_exists(options = {})
      if lookup_context.template_exists?(options[:partial] || options[:template], options[:path], options.key?(:partial))
        render(options)
      end
    end
  end
end