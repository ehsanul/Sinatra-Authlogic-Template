# Authlogic calls controller.request.remote_ip (Authlogic::Session::MagicColumns#update_info, line 60)
# It should call controller.remote_ip instead so that the adapter class can handle it
class Sinatra::Request; alias :remote_ip :ip; end

module Authlogic
  module ControllerAdapters
    class SinatraAdapter < AbstractAdapter
      def cookies
        unless defined? @cookies
          class << @cookies = Object.new
            # The []= method is one of the reasons for the @cookies object. Authlogic seems to expect
            #  a hash that it can set, whereas rack has a the set_cookie method for this purpose.
            # Authlogic should call set_cookie instead and then add the set_cookie method to the adapters
            def []= ( key, value )
              Authlogic::Session::Base.controller.response.set_cookie key, value
            end
            # The delete method is the other reason for the @cookies object creation
            # If request.cookies hash is returned instead of this object, the Hash#delete method takes only one argument,
            #  while authlogic expects it to take two arguments, just as Rack::Response#delete_cookie does
            # (see Authlogic::Session::Cookies#destroy, line 125 in authlogic/session/cookies.rb)
            # Authlogic should really just call delete_cookie instead of cookies.delete,
            #  and add a delete_cookie method in the adapters
            def delete( key, value = {} )
              Authlogic::Session::Base.controller.response.delete_cookie key, value
            end
            # Immitate the rack::request cookies hash.
            def method_missing( meth, *args, &block )
              Authlogic::Session::Base.controller.request.cookies.send meth, *args, &block
            end
          end
        end
        @cookies
      end
      
      def response
        controller.response
      end
      
      def cookie_domain
        if Sinatra::Base.development?
          nil  # This works, browsers only allow access to the cookie issuing domain
               # But it's better to specify explicitly 
        else
          '.' + request.host  # request.host doesn't work, atleast in development, probably incorrect
                              # Browser doesn't send the cookie back on subsequent requests (cookie_domain set to 'localhost')
                              # Needs to be tested in production environment
        end
      end
      
      def params
        request.params
      end
      
      def session
        controller.session
      end
    end
  end
end

# Making sure this is a Sinatra app
# Note: Sinatra must be required before sinadapt, otherwise the before filter must be set within the app
if defined? Sinatra::Base
  before do
    Authlogic::Session::Base.controller = Authlogic::ControllerAdapters::SinatraAdapter.new(self)
  end
end
