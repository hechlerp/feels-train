require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'


$characters = [
  { id: 1, name: "John Coffey" },
  { id: 2, name: "Robb Stark" }
]

$statuses = [
  { id: 1, character_id: 1, text: "Like the drink, only not spelled the same." },
  { id: 2, character_id: 2, text: "The Lannisters sent me their regards." },
  { id: 3, character_id: 1, text: "That's a smart mouse, Del, he's like a circus mouse." }
]

class StatusesController < ControllerBase
  def index
    statuses = $statuses.select do |s|
      s[:character_id] == Integer(params['character_id'])
    end

    render_content(statuses.to_json, "application/json")
  end
end

class Characters2Controller < ControllerBase
  def index
    render_content($characters.to_json, "application/json")
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/characters$"), Characters2Controller, :index
  get Regexp.new("^/characters/(?<character_id>\\d+)/statuses$"), StatusesController, :index
end

app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  router.run(req, res)
  res.finish
end

Rack::Server.start(
 app: app,
 Port: 3000
)
