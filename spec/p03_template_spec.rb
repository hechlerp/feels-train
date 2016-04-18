require 'rack'
require 'controller_base'

describe ControllerBase do
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
  let(:characters_controller) { CharactersController.new(req, res) }

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
end
