$LOAD_PATH.unshift *Dir.entries('vendor').map{|gem| File.join '.', gem, 'lib'}
require 'rubygems'
require 'rack'
require 'sinatra'

set :run, false
set :environment, :production
set :views, File.join(File.dirname(__FILE__), 'views')

require 'sin-auth-template.rb'
run Sinatra::Application 
