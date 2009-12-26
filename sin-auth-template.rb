$LOAD_PATH.unshift *Dir.entries('vendor').map{|gem| File.join '.', gem, 'lib'}
$LOAD_PATH.uniq!
['rubygems', 'yaml', 'sinatra', 'haml', 'active_record', 'authlogic', 'pony', 'user'].each { |lib| require lib }
load 'signup and login.rb'

configure do
  enable :sessions
  dbconfig = YAML::load( File.open('db/config.yml') )
  ActiveRecord::Base.establish_connection(dbconfig)
end

# Work around a bug in authlogic.  See:
#     http://github.com/binarylogic/authlogic/issuesearch?state=open&q=remote_ip#issue/80
class Sinatra::Request
  alias remote_ip ip
end

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

Notice = Struct.new(:msg).new

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

