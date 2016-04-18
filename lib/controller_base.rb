require 'active_support'
require 'active_support/core_ext'
require 'erb'
require 'active_support/inflector'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  def initialize(req, res, params = {})
    @params = params.merge(req.params)
    @req = req
    @res = res
  end

  def already_built_response?
    return true if @done
    @done = true
    false
  end

  def redirect_to(url)
    raise "You've done that yourself. ~ Ewan McGregor" if already_built_response?
    res.status = 302
    res["Location"] = url
    session.store_session(res)
  end

  def render_content(content, content_type)
    raise "You've done that yourself. ~ Ewan McGregor" if already_built_response?
    res['Content-Type'] = content_type
    res.write(content)
    session.store_session(res)

  end

  def render(template_name)
    template = File.read "views/#{self.class.to_s.underscore}/#{template_name}.html.erb"
    content = ERB.new(template).result(binding)
    render_content(content, 'text/html')
  end

  def session
    @session ||= Session.new(req)
  end

  def invoke_action(name)
    send(name)
    unless already_built_response?
      render(name)
    end
  end
end
