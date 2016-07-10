# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'yaml'
require 'dm-migrations'

require_relative 'home-library-manager/book.rb'
require_relative 'home-library-manager/author.rb'
require_relative 'home-library-manager/subject.rb'
require_relative 'home-library-manager/review.rb'
require_relative 'home-library-manager/borrower.rb'

class HomeLibraryManager < Sinatra::Base

  def initialize
    super
    config = YAML.load(File.open('config.yml'))
    DataMapper::Logger.new($stdout, :debug) # for debugging
    DataMapper.setup(:default, "mysql://#{config['user']}:#{config['pass']}@#{config['host']}/#{config['database']}")
    DataMapper.finalize
    DataMapper.auto_migrate!
  end

  get '/' do
    
  end

  run! if app_file == $0
end
