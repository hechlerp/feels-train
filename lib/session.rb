require 'json'

class Session
  def initialize(req)
    if req.cookies["_feels_train_app"].nil?
      @session = {}
    else
      @session = JSON.parse(req.cookies["_feels_train_app"])
    end
  end

  def [](key)
    value = @session[key]

  end

  def []=(key, val)
    @session[key] = val
  end

  def store_session(res)
    res.set_cookie("_feels_train_app",{path: "/", value: @session.to_json})

  end
end
