require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'active_support/inflector'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res, params = {})
    @params = params.merge(req.params)
    @req = req
    @res = res
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    return true if @done
    @done = true
    false
  end

  # Set the response status code and header
  def redirect_to(url)
    raise "You've done that yourself. ~ Ewan McGregor" if already_built_response?
    res.status = 302
    res["Location"] = url
    session.store_session(res)
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    raise "You've done that yourself. ~ Ewan McGregor" if already_built_response?
    res['Content-Type'] = content_type
    res.write(content)
    session.store_session(res)

  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    template = File.read "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    content = ERB.new(template).result(binding)
    render_content(content, 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    send(name)
    unless already_built_response?
      render(name)
    end
  end
end
