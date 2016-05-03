require 'rack'
require 'session'
require 'router'
require 'controller_base'

describe ControllerBase do

  before(:all) do
    class UsersController < ControllerBase
      def index
      end
    end
  end
  after(:all) { Object.send(:remove_const, "UsersController") }

  before(:all) do
    class CharactersController < ControllerBase
      def index
        @characters = ["Mufasa"]
      end
    end
  end
  after(:all) { Object.send(:remove_const, "CharactersController") }

  let(:req) { Rack::Request.new({'rack.input' => {}}) }
  let(:res) { Rack::MockResponse.new('200', {}, []) }
  let(:users_controller) { UsersController.new(req, res) }
  let(:characters_controller) { CharactersController.new(req, res, { 'key' => 'val' } ) }

  context '#initialize' do
    it "includes route params in the params object" do
      expect(characters_controller.params['key']).to eq('val')
    end
  end
  
  describe "#render_content" do
    before(:each) do
      users_controller.render_content "somebody", "text/html"
    end

    it "sets the response content type" do
      expect(res['Content-Type']).to eq("text/html")
    end

    it "sets the response body" do
      expect(res.body).to eq("somebody")
    end

    describe "#already_built_response?" do
      let(:users_controller2) { UsersController.new(req, res) }

      it "is false before rendering" do
        expect(users_controller2.already_built_response?).to be_falsey
      end

      it "is true after rendering content" do
        users_controller2.render_content "somebody", "text/html"
        expect(users_controller2.already_built_response?).to be_truthy
      end

      it "raises an error when attempting to render twice" do
        users_controller2.render_content "somebody", "text/html"
        expect do
          users_controller2.render_content "somebody", "text/html"
        end.to raise_error
      end
    end
  end

  describe "#redirect" do
    before(:each) do
      users_controller.redirect_to("http://www.google.com")
    end

    it "sets the header" do
      expect(users_controller.res.header["location"]).to eq("http://www.google.com")
    end

    it "sets the status" do
      expect(users_controller.res.status).to eq(302)
    end

    describe "#already_built_response?" do
      let(:users_controller2) { UsersController.new(req, res) }

      it "is false before rendering" do
        expect(users_controller2.already_built_response?).to be_falsey
      end

      it "is true after rendering content" do
        users_controller2.redirect_to("http://google.com")
        expect(users_controller2.already_built_response?).to be_truthy
      end

      it "raises an error when attempting to render twice" do
        users_controller2.redirect_to("http://google.com")
        expect do
          users_controller2.redirect_to("http://google.com")
        end.to raise_error
      end
    end
  end

  describe "#render" do
    before(:each) do
      characters_controller.render(:index)
    end

    it "renders the html of the index view" do
      expect(characters_controller.res.body).to include("Full Character List")
      expect(characters_controller.res.body).to include("<h1>")
      expect(characters_controller.res['Content-Type']).to eq("text/html")
    end

    describe "#already_built_response?" do
      let(:characters_controller2) { CharactersController.new(req, res) }

      it "is false before rendering" do
        expect(characters_controller2.already_built_response?).to be_falsey
      end

      it "is true after rendering content" do
        characters_controller2.render(:index)
        expect(characters_controller2.already_built_response?).to be_truthy
      end

      it "raises an error when attempting to render twice" do
        characters_controller2.render(:index)
        expect do
          characters_controller2.render(:index)
        end.to raise_error
      end
    end
  end

  describe "#session" do
    it "returns a session instance" do
      expect(characters_controller.session).to be_a(Session)
    end

    it "returns the same instance on successive invocations" do
      first_result = characters_controller.session
      expect(characters_controller.session).to be(first_result)
    end
  end

  shared_examples_for "storing session data" do
    it "should store the session data" do
      characters_controller.session['test_key'] = 'test_value'
      characters_controller.send(method, *args)
      cookie_str = res['Set-Cookie']
      cookie = Rack::Utils.parse_query(cookie_str)
      cookie_val = cookie["_feels_train_app"]
      cookie_hash = JSON.parse(cookie_val)
      expect(cookie_hash['test_key']).to eq('test_value')
    end
  end

  describe "#render_content" do
    let(:method) { :render_content }
    let(:args) { ['test', 'text/plain'] }
    include_examples "storing session data"
  end

  describe "#redirect_to" do
    let(:method) { :redirect_to }
    let(:args) { ['http://appacademy.io'] }
    include_examples "storing session data"
  end

end

describe Session do
  let(:req) { Rack::Request.new({'rack.input' => {}}) }
  let(:res) { Rack::Response.new([], '200', {}) }
  let(:cook) { {"_feels_train_app" => { 'xyz' => 'abc' }.to_json} }

  it "deserializes json cookie if one exists" do
    req.cookies.merge!(cook)
    session = Session.new(req)
    expect(session['xyz']).to eq('abc')
  end

  describe "#store_session" do
    context "without cookies in request" do
      before(:each) do
        session = Session.new(req)
        session['first_key'] = 'first_val'
        session.store_session(res)
      end

      it "adds new cookie with '_feels_train_app' name to response" do
        cookie_str = res.headers['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        expect(cookie["_feels_train_app"]).not_to be_nil
      end

      it "stores the cookie in json format" do
        cookie_str = res.headers['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        cookie_val = cookie["_feels_train_app"]
        cookie_hash = JSON.parse(cookie_val)
        expect(cookie_hash).to be_instance_of(Hash)
      end
    end

    context "with cookies in request" do
      before(:each) do
        cook = {'_feels_train_app' => { 'pho' =>  "soup" }.to_json }
        req.cookies.merge!(cook)
      end

      it "reads the pre-existing cookie data into hash" do
        session = Session.new(req)
        expect(session['pho']).to eq('soup')
      end

      it "saves new and old data to the cookie" do
        session = Session.new(req)
        session['machine'] = 'mocha'
        session.store_session(res)
        cookie_str = res['Set-Cookie']
        cookie = Rack::Utils.parse_query(cookie_str)
        cookie_val = cookie["_feels_train_app"]
        cookie_hash = JSON.parse(cookie_val)
        expect(cookie_hash['pho']).to eq('soup')
        expect(cookie_hash['machine']).to eq('mocha')
      end
    end
  end

end

describe Route do
  let(:req) { Rack::Request.new({'rack-input' => {}}) }
  let(:res) { Rack::MockResponse.new('200', {}, []) }

  before(:each) do
    allow(req).to receive(:request_method).and_return("GET")
  end

  describe "#matches?" do
    it "matches simple regular expression" do
      index_route = Route.new(Regexp.new("^/users$"), :get, "x", :x)
      allow(req).to receive(:path) { "/users" }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_truthy
    end

    it "matches regular expression with capture" do
      index_route = Route.new(Regexp.new("^/users/(?<id>\\d+)$"), :get, "x", :x)
      allow(req).to receive(:path) { "/users/1" }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_truthy
    end

    it "correctly doesn't matche regular expression with capture" do
      index_route = Route.new(Regexp.new("^/users/(?<id>\\d+)$"), :get, "UsersController", :index)
      allow(req).to receive(:path) { "/statuses/1" }
      allow(req).to receive(:request_method) { 'GET' }
      expect(index_route.matches?(req)).to be_falsey
    end
  end

  describe "#run" do
    before(:all) { class DummyController; end }
    after(:all) { Object.send(:remove_const, "DummyController") }

    it "instantiates controller and invokes action" do
      allow(req).to receive(:path) { "/users" }

      dummy_controller_class = DummyController
      dummy_controller_instance = DummyController.new
      allow(dummy_controller_instance).to receive(:invoke_action)
      allow(dummy_controller_class).to receive(:new).with(req, res, {}) do
        dummy_controller_instance
      end
      expect(dummy_controller_instance).to receive(:invoke_action)
      index_route = Route.new(Regexp.new("^/users$"), :get, dummy_controller_class, :index)
      index_route.run(req, res)
    end
  end
end

describe Router do
  let(:req) { Rack::Request.new({'rack-input' => {}}) }
  let(:res) { Rack::MockResponse.new('200', {}, []) }

  describe "#add_route" do
    it "adds a route" do
      subject.add_route(1, 2, 3, 4)
      expect(subject.routes.count).to eq(1)
      subject.add_route(1, 2, 3, 4)
      subject.add_route(1, 2, 3, 4)
      expect(subject.routes.count).to eq(3)
    end
  end

  describe "#match" do
    it "matches a correct route" do
      subject.add_route(Regexp.new("^/users$"), :get, :x, :x)
      allow(req).to receive(:path) { "/users" }
      allow(req).to receive(:request_method) { 'GET' }
      matched = subject.match(req)
      expect(matched).not_to be_nil
    end

    it "doesn't match an incorrect route" do
      subject.add_route(Regexp.new("^/users$"), :get, :x, :x)
      allow(req).to receive(:path) { "/incorrect_path" }
      allow(req).to receive(:request_method) { 'GET' }
      matched = subject.match(req)
      expect(matched).to be_nil
    end
  end

  describe "#run" do
    it "sets status to 404 if no route is found" do
      subject.add_route(Regexp.new("^/users$"), :get, :x, :x)
      allow(req).to receive(:path).and_return("/incorrect_path")
      allow(req).to receive(:request_method).and_return("GET")
      subject.run(req, res)
      expect(res.status).to eq(404)
    end
  end

  describe "http method (get, put, post, delete)" do
    it "adds methods get, put, post and delete" do
      router = Router.new
      expect((router.methods - Class.new.methods)).to include(:get)
      expect((router.methods - Class.new.methods)).to include(:put)
      expect((router.methods - Class.new.methods)).to include(:post)
      expect((router.methods - Class.new.methods)).to include(:delete)
    end

    it "adds a route when an http method method is called" do
      router = Router.new
      router.get Regexp.new("^/users$"), ControllerBase, :index
      expect(router.routes.count).to eq(1)
    end
  end

  describe "#draw" do
    it "calls http method methods with the route information to add the route" do
      index_route = double('route')
      post_route = double('route')

      routes = Proc.new do
        get index_route
        post post_route
      end

      router = Router.new

      expect(router).to receive(:get).with(index_route)
      expect(router).to receive(:post).with(post_route)

      router.draw(&routes)
    end
  end
end
