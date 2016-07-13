require 'yaml'
require 'data_mapper'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = 'spec/*_spec.rb'
    t.verbose = true
end

task :test => :spec

task :setup do
  unless File.exists?('library_config.yml')
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
    File.touch('index.html')

    File.open('library_config.yml', 'w') do |f|
      f.write(data.to_yaml)
      f.flush
    end

    puts 'Please edit the library_config.yml file with your information before attempting to run the service.'
    exit 1
  end

  unless File.exists?('index.html')
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
end

task :setup_travis do
  File.open('library_config.yml', 'w') do |f|
    f.write(
        '---
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

task :default => [:setup, :test]