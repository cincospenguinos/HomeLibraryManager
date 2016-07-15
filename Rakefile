require 'yaml'
require 'data_mapper'
require 'rspec/core/rake_task'

desc 'Runs the RSpect test cases'
RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/*_spec.rb'
    t.verbose = true
end

desc 'Runs the RSpec test cases'
task :test => :spec

desc 'Creates the library_config file'
file 'library_config.yml' do
  data = {}

  data[:database] = {}
  data[:database][:db_user] = 'DB_USERNAME_HERE'
  data[:database][:db_password] = 'DB_PASSWORD_HERE'
  data[:database][:db_hostname] = 'DB_HOSTNAME_HERE'
  data[:database][:db_name] = 'DB_NAME_HERE'
  data[:database][:db_engine] = 'DB_ENGINE_HERE'

  data[:data_mapper] = {}
  data[:data_mapper][:logger_std_out] = false
  data[:data_mapper][:rase_on_save_failure] = true
  data[:root_file] = 'index.html'

  File.open('library_config.yml', 'w') do |f|
    f.write(data.to_yaml)
    f.flush
  end

  puts 'Please edit the library_config.yml file with your information before attempting to run the service.'
  exit 1
end

desc 'Creates the GET "/" file'
file 'index.html' do
  File.open('index.html', 'w') do |f|
    f.write("
        <!DOCTYPE HTML>
        <html>
          <head>
            <title>Modify this page!</title>
          </head>
          <body>
            <h1>Modify this page!</h1>
            <p>Modify this page however you'd like! It gets loaded by default on a GET request at '/' for this service</p>
          </body>
        </html>
              ")
    f.flush
  end
end

desc 'Creates the necessary files to be able to run the service'
task :setup => ['index.html', 'library_config.yml']

desc 'Sets things up only for the Travis-CI environment'
task :setup_travis do
  File.open('library_config.yml', 'w') do |f|
    f.write ('---
:database:
  :db_user: travis
  :db_password:
  :db_hostname: localhost
  :db_name: HomeLibraryManager_test
  :db_engine: mysql
:data_mapper:
  :logger_std_out: true
  :raise_on_save_failure: true
:root_file: \'index.html\'
')
    f.flush
  end
end

desc 'Sets up the database according to the library_config.yml file'
task :db do
  db_config = YAML.load(File.read('library_config.yml'))[:database]
  data_mapper_config = YAML.load(File.read('library_config.yml'))[:data_mapper]

  begin
    DataMapper.setup(:default, "#{db_config[:db_engine]}://#{db_config[:db_user]}:#{db_config[:db_password]}@#{db_config[:db_hostname]}/#{db_config[:db_name]}")
    # TODO: Change this line to work for all DB engines
  rescue LoadError
    puts 'An adapter cannot be found for the given DB engine! (are you sure your db engine is correct?)'
    exit 1
  end

  if data_mapper_config[:logger_std_out]
    DataMapper::Logger.new($stdout, :debug) # for debugging
  end

  DataMapper::Model.raise_on_save_failure = data_mapper_config[:raise_on_save_failure]
  DataMapper.finalize

  # NOTE: This deletes anything relevant to the book library and recreates everything! ALL DATA WILL BE LOST!
  DataMapper.auto_migrate!
end

desc 'Sets up the various files and sets up the database.'
task :default => [:setup, :db]

desc 'Sets up the various files and sets up the database.'
task :build => :default
