require 'json'

class Session
  def initialize(req)
    if req.cookies["_rails_lite_app"].nil?
      @session = {}
    else
      @session = JSON.parse(req.cookies["_rails_lite_app"])
    end
  end

  def [](key)
    value = @session[key]

  end

  def []=(key, val)
    @session[key] = val
  end

  def store_session(res)
    res.set_cookie("_rails_lite_app",{path: "/", value: @session.to_json})

  end
end
