[Demo][heroku]

[heroku]: http://feels-train.herokuapp.com/characters

#FeelsTrain

FeelsTrain is a lightweight MVC architecture, built using Ruby. It allows a user to run a server on localhost with Rack
middleware and create routes for CRUD functionality.

###Technical Details

Routes are created through methods with the names of HTTP methods (get, post, put, and delete). Each of these methods takes 3
additional arguments to describe the url at which to get called, the controller to look at, and the name of the method that
it should look for in the controller. Each of these methods then creates a route with the attributes passed in. This is
accomplished through metaprogramming, as follows:

    def initialize
      @routes = []
    end

    def add_route(pattern, method, controller_class, action_name)
      route = Route.new(pattern, method, controller_class, action_name)
      @routes << route
    end

    def draw(&proc)
      self.instance_eval(&proc)

    end

    [:get, :post, :put, :delete].each do |http_method|
      define_method(http_method) do |pattern, controller_class, action_name|
        add_route(pattern, http_method, controller_class, action_name)
      end
    end

I then use a separate method to check if an inputted request matches a route, which returns a 404 error if there is no such
route. Otherwise, it runs the route.

    def match(req)
      @routes.each do |route|
        return route if route.matches?(req)
      end
      nil
    end

    def run(req, res)
      route = match(req)
      if route
        route.run(req, res)
      else
        res.body = ["No route there, sir."]
        res.status = 404
      end
    end

The match method uses a regex matcher inside the Route class, and the Route#run method calls the action on the given route.

    def matches?(req)
      @pattern =~ req.path && req.request_method
        .downcase.to_sym == @http_method
    end

    def run(req, res)
      path = Regexp.new @pattern
      matched = path.match(req.path)
      route_params = {}
      matched.names.each do |name|
        route_params[name] = matched[name]
      end

      controller = controller_class.new(req, res, route_params)
      controller.invoke_action(action_name)
    end

This framework makes it relatively easy for a user to set up a new route. All it requires is a regex for the path, the http
method, and then where and what you want to call it.

Another major function of the app is the base controller, which handles requests and responses. It also allows for easy
access to corresponding views through its ControllerBase#render method. By passing in the name of the view you want to render,
it attempts to read an ERB file with that name in a folder with the name of the controller. It then renders the content it
finds unless it has already attempted to do so.

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

By using class inheritance, any controller can simply use render and the view name as a symbol to direct the route to render
a view. This makes controller creation very DRY and easy to work with. As an example, here is the method for using the
characters' 'new' route in the demo:

    def new
      render :new
    end

###Features

- Users can create routes by passing in an http method, a path, a controller, and a method name.
- Controllers read routes and find corresponding views.
- Controllers require very little setup outside of inheriting from the ControllerBase class.
- RSpec tests verify that the core functionality is still in place when manipulating code.

###To-do

- [ ] Add CSRF authenticity token verification.
- [ ] Enforce strong params to block bad input.
- [ ] Improve error messages to be more helpful when the app breaks.
