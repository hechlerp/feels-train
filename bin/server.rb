require 'rack'
require_relative '../lib/controller_base'
require_relative '../lib/router'

$characters = [
  { id: 1, name: "John Coffey" },
  { id: 2, name: "Eddard Stark" },
  { id: 3, name: "Lady MacDuff"},
  { id: 4, name: "Sayaka Miki"},
  { id: 5, name: "Lennie Small"},
  { id: 6, name: "Atahualpa"},
  { id: 7, name: "Alexander the Great"},
  { id: 8, name: "Oedipus"}
]

$character_id_counter = 9

$statuses = [
  { id: 1, character_id: 1, quote: "Like the drink, only not spelled the same." },
  { id: 2, character_id: 2, quote: "You think my life is some precious thing to me? That I would trade my honor for a few more years... of what? You grew up with actors. You learned their craft and you learnt it well. But I grew up with soldiers. I learned to die a long time ago. " },
  { id: 3, character_id: 1, quote: "That's a smart mouse, Del, he's like a circus mouse." },
  { id: 4, character_id: 4, quote: "I was stupid...so stupid..." },
  { id: 5, character_id: 5, quote: "And the rabbits, George!" },
  { id: 6, character_id: 3, quote: "Whither should I fly? \n
    I have done no harm. But I remember now \n
    I am in this earthly world; where to do harm \n
    Is often laudable, to do good sometime \n
    Accounted dangerous folly: why then, alas, \n
    Do I put up that womanly defence, \n
    To say I have done no harm? \n
    [Enter Murderers] \n
    What are these faces?" },
  { id: 7, character_id: 8, quote: "You, you'll see no more the pain I suffered, all the pain I caused! Too long you looked on the ones you never should have seen, blind to the ones you longed to see, to know! Blind from this hour on! Blind in the darkness-blind!" }
]

$status_id_counter = 8

class StatusesController < ControllerBase
  def index
    @statuses = $statuses.select do |s|
      s[:character_id] == Integer(params['character_id'])
    end
    render :index
  end
end

class Characters2Controller < ControllerBase
  def index
    @characters = $characters
    render :index
  end

  def new
    @character = {name: "Write name here"}
    render :new
  end

  def create
    @character = { id: $character_id_counter, name: params["character"]["name"] }
    $characters << @character
    $character_id_counter += 1
    redirect_to "/characters"
  end
end

router = Router.new
router.draw do
  get Regexp.new("^/characters$"), Characters2Controller, :index
  get Regexp.new("^/characters/new$"), Characters2Controller, :new
  post Regexp.new("^/characters$"), Characters2Controller, :create
  get Regexp.new("^/characters/(?<character_id>\\d+)/statuses$"), StatusesController, :index
  get Regexp.new("^/characters/(?<character_id>\\d+)/statuses$"), StatusesController, :new
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
