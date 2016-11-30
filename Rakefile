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

desc 'Sets things up only for the Travis-CI environment'
task :setup_travis do
  File.open('library_config.yml', 'w') do |f|
    f.write ('---
:test:
  :database:
    :db_user: travis
    :db_password:
    :db_hostname: localhost
    :db_name: HomeLibraryManager_test
    :db_engine: mysql
  :data_mapper:
    :logger_std_out: true
    :raise_on_save_failure: true
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
