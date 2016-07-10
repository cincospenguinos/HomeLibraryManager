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
    books = []
    # TODO: This ---> THIS SO HARD
    if params.empty?
      Book.all().each do |book|
        authors = []

        Authors.all(:books => book.book_id).each do |auth|
          authors.push(auth)
        end

        books.push(book)
      end
    end

    generate_response(true, books, '')
  end

  get '/setup' do
    # This exists solely for setting up development stuff
    book = Book.create(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
    author = Author.create(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
    author = Author.create(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
    Subject.create(:name => 'Non-fiction', :book => book)
    Subject.create(:name => 'Literary Theory', :book => book)

    book = Book.create(:isbn => '978-0-679-73452-9', :title => 'Notes from Underground')
    author = Author.create(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
    Subject.create(:name => 'Fiction', :book => book)
    Subject.create(:name => 'Literature', :book => book)
    
    book = Book.create(:isbn => '978-0-06-093434-7', :title => 'Don Quixote')
    author = Author.create(:last_name => 'De Cervantes', :first_name => 'Miguel', :book => book)
    Subject.create(:name => 'Fiction', :book => book)
    Subject.create(:name => 'Literature', :book => book)

    book = Book.create(:isbn => '978-1-59308-244-4', :title => 'Utopia')
    author = Author.create(:last_name => 'More', :first_name => 'Thomas', :book => book)
    Subject.create(:name => 'Philosophy', :book => book)

    generate_response(true, [], "Stuff: #{author.errors.inspect}")
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
