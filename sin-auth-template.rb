['rubygems', 'yaml', 'sinatra', 'haml', 'active_record', 'authlogic', 'sinadapt'].each { |lib| require lib }

configure do
  enable :sessons
  dbconfig = YAML::load( File.open('db/config.yml') )
  ActiveRecord::Base.establish_connection(dbconfig)
end

class UserSession < Authlogic::Session::Base; end

class User < ActiveRecord::Base
  acts_as_authentic
end

Notice = Struct.new(:msg).new

# Rails style nested params
before do
  new_params = {}
  params.each_pair do |full_key, value|
    this_param = new_params
    split_keys = full_key.split(/\]\[|\]|\[/)
    split_keys.each_index do |index|
      break if split_keys.length == index + 1
      this_param[split_keys[index]] ||= {}
      this_param = this_param[split_keys[index]]
   end
   this_param[split_keys.last] = value
  end
  request.params.replace new_params
end

helpers do
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end
  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.record
  end
  def restrict
    ( notify 'You must be logged in to view that page'; redirect '/login' ) unless current_user
  end
  def notify( msg )
    if Notice.msg.nil? then Notice.msg = msg
    else Notice.msg += '<br/>' + msg
    end
  end
  def notice
    msg = Notice.msg
    Notice.msg = nil; msg
  end
  def link name, url
    "<a href=\"#{url}\">#{name}</a>"
  end
end

get '/' do
  haml :index
end

get '/restricted' do
  restrict
  haml "You're logged in, so you got into a restricted page"
end

get '/show' do
  restrict
  @user = current_user
  haml :show
end

get '/login' do
  haml :login
end

post '/login' do
  puts params.inspect
  @user_session = UserSession.new(params[:user])
  if @user_session.save
    notify "You're logged in!"
    redirect '/show'
  else
    notify "Login didn't work. Try again?"
    haml :login
  end
end

get '/logout' do
  current_user_session.destroy
  notify "You logged out!"
  redirect '/login'
end

get '/register' do
  haml :register
end

post '/register' do
  @user = User.new(params[:user])
  if @user.save
    notify "Registration Successful. Try logging in"
    redirect '/login'
  else
    notify "Registration Failed. Try again?"
    haml :register
  end
end
