require 'rake'
require 'active_record'
require 'yaml'

task :default => :dbsetup

task :loadconfig do
  DBconfig = YAML::load( File.open('db/config.yml') )['development']
end

task :dbsetup => :loadconfig do
  create(DBconfig)
  migrate(DBconfig)
end

task :migrate => :loadconfig do
  migrate(DBconfig)
end

def create( config )
  begin
    if config['adapter'] =~ /sqlite/
      if File.exist?(config['database'])
        $stderr.puts "#{config['database']} already exists"
      else
        begin
          # Create the SQLite database
          ActiveRecord::Base.establish_connection(config)
          ActiveRecord::Base.connection
        rescue
          $stderr.puts $!, *($!.backtrace)
          $stderr.puts "Couldn't create database for #{config.inspect}"
        end
      end
      return # Skip the else clause of begin/rescue    
    else
      ActiveRecord::Base.establish_connection(config)
      ActiveRecord::Base.connection
    end
  rescue
    case config['adapter']
    when 'mysql'
      @charset   = ENV['CHARSET']   || 'utf8'
      @collation = ENV['COLLATION'] || 'utf8_general_ci'
      begin
        ActiveRecord::Base.establish_connection(config.merge('database' => nil))
        ActiveRecord::Base.connection.create_database(config['database'], :charset => (config['charset'] || @charset), :collation => (config['collation'] || @collation))
        ActiveRecord::Base.establish_connection(config)
      rescue
        $stderr.puts "Couldn't create database for #{config.inspect}, charset: #{config['charset'] || @charset}, collation: #{config['collation'] || @collation} (if you set the charset manually, make sure you have a matching collation)"
      end
    when 'postgresql'
      @encoding = config[:encoding] || ENV['CHARSET'] || 'utf8'
      begin
        ActiveRecord::Base.establish_connection(config.merge('database' => 'postgres', 'schema_search_path' => 'public'))
        ActiveRecord::Base.connection.create_database(config['database'], config.merge('encoding' => @encoding))
        ActiveRecord::Base.establish_connection(config)
      rescue
        $stderr.puts $!, *($!.backtrace)
        $stderr.puts "Couldn't create database for #{config.inspect}"
      end
    end
  else
    $stderr.puts "#{config['database']} already exists"
  end
end

def migrate( config )
  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.establish_connection(config)
  ActiveRecord::Migrator.up "db/migrate/"
end
