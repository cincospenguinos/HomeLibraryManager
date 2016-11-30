require 'rack'
require_relative 'lib/home_library_manager'

@config = YAML.load(File.read('library_config.yml'))
db_config = @config[:database]
data_mapper_config = @config[:data_mapper]
DataMapper.setup(:default, "#{db_config[:db_engine]}://#{db_config[:db_user]}:#{db_config[:db_password]}@#{db_config[:db_hostname]}/#{db_config[:db_name]}")

if data_mapper_config[:logger_std_out] # TODO: Log to file?
  DataMapper::Logger.new($stdout, :debug, '[DataMapper]') # for debugging
end

DataMapper::Model.raise_on_save_failure = data_mapper_config[:raise_on_save_failure]
DataMapper.finalize
DataMapper.auto_upgrade!

run HomeLibraryManager