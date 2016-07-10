# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'
require 'yaml'
require 'json'

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

  before do
    content_type 'application/json'
  end

  # Show the index file
  get '/' do
    File.read('api.html')
  end

  # Run queries on current books in the library
  get '/books' do
    book = Book.create(
      :isbn => 'bologna',
      :title => 'Bologna in Bologna',
    )

    

  end

  # Add a book to the library
  post '/books' do
  end

  # Remove a book from the library
  delete '/books' do
  end

  # Let the service know a book is being checked out
  post '/checkout' do
  end

  # Let the service know a book is being checked in
  post '/checkin' do
  end

  # Submit a review on a book
  post '/review' do
  end

private

  def generate_response(successful, results, message)
    resp = {}
    resp['successful'] = successful
    resp['results'] = results
    resp['message'] = message
    resp.to_json
  end

  run! if app_file == $0 # This is mostly for debugging
end
