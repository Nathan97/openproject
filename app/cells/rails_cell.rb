class RailsCell < Cell::ViewModel
  include Escaped
  include ApplicationHelper
  include ActionView::Helpers::TranslationHelper
  include SecureHeaders::ViewHelpers

  self.view_paths = ['app/cells/views']

  # We don't include ActionView::Helpers wholesale because
  # this would override Cell's own render method and
  # subsequently break everything.

  def self.options(*names)
    names.each do |name|
      define_method(name) do
        options[name]
      end
    end
  end

  def show
    # Set the _request from AS::Controller that doesn't get passed into the rails cell.
    # Workaround for when using middlewares such as SecureHeaders that relies on it,
    # but don't use the request method itself.
    @_request = request

    render
  end

  def controller
    context[:controller]
  end

  def protect_against_forgery?
    controller.send(:protect_against_forgery?)
  end

  def form_authenticity_token(*args)
    controller.send(:form_authenticity_token, *args)
  end

  # override cell-erb's behaviour to not escape
  # https://github.com/trailblazer/cells-erb/tree/v0.1.0#html-escaping
  def content_tag(name, content_or_options_with_block = nil, options = nil, escape = true, &block)
    super
  end

  def request
    controller.request
  end
end
