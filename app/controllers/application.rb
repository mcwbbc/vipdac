# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base

  helper :all # include all helpers, all the time

  before_filter :no_cache

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'b6ff5f8311772a476ad7556fc4325b03'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  filter_parameter_logging :aws_secret, :password

  private
    def no_cache
      response.headers["Last-Modified"] = Time.now.httpdate
      response.headers["Expires"] = "0"
      # HTTP 1.0
      response.headers["Pragma"] = "no-cache"
      # HTTP 1.1 ‘pre-check=0, post-check=0′ (IE specific)
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0"
    end

end
