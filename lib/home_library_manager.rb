# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'
require 'yaml'
require 'json'

require_relative 'library_manager/book.rb'
require_relative 'library_manager/author.rb'
require_relative 'library_manager/subject.rb'
require_relative 'library_manager/review.rb'
require_relative 'library_manager/borrower.rb'
require_relative 'library_manager/book_information_manager'

class HomeLibraryManager < Sinatra::Base

  def initialize
    super
    config = YAML.load(File.open('config.yml'))
    DataMapper::Logger.new($stdout, :debug) # for debugging
    DataMapper.setup(:default, "#{config['dbengine']}://#{config['user']}:#{config['pass']}@#{config['host']}/#{config['database']}")
    DataMapper::Model.raise_on_save_failure = true
    DataMapper.finalize
    DataMapper.auto_migrate!

    # # This exists solely for setting up development stuff
    # book = Book.create(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
    # author = Author.create(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
    # author = Author.create(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
    # Subject.create(:subject => 'Non-Fiction', :book => book)
    # Subject.create(:subject => 'Literary Theory', :book => book)
    #
    # book = Book.create(:isbn => '978-0-679-73452-9', :title => 'Notes from Underground')
    # author = Author.create(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
    # Subject.create(:subject => 'Fiction', :book => book)
    # Subject.create(:subject => 'Literature', :book => book)
    # Subject.create(:subject => 'Philosophy', :book => book)
    #
    # book = Book.create(:isbn => '978-0-06-093434-7', :title => 'Don Quixote')
    # author = Author.create(:last_name => 'De Cervantes', :first_name => 'Miguel', :book => book)
    # Subject.create(:subject => 'Fiction', :book => book)
    # Subject.create(:subject => 'Literature', :book => book)
    #
    # book = Book.create(:isbn => '978-1-59308-244-4', :title => 'Utopia')
    # author = Author.create(:last_name => 'More', :first_name => 'Thomas', :book => book)
    # Subject.create(:subject => 'Philosophy', :book => book)

    # Setup an instance of BookInformationManager
    @manager = BookInformationManager.new
  end

  before do
    content_type 'application/json'
  end

  # Show the index file
  get '/' do
    content_type :html
    File.read('api.html')
  end

  # Run queries on current books in the library
  get '/books' do
    params.keys.each do |key|
      params[(key.to_sym rescue key) || key] = params.delete(key)
    end

    generate_response(true, @manager.get_all_books(params), '')
  end

  # Add a book to the library
  post '/books' do
    # TODO: User validation?
    params.keys.each do |key|
      params[(key.to_sym rescue key) || key] = params.delete(key)
    end

    params[:author_last] = [params[:author_last]] if params[:author_last].is_a?(String)
    params[:author_first] = [params[:author_first]] if params[:author_first].is_a?(String)
    
    message = new_book_valid_params(params)
    
    generate_response(false, [], message) if message.is_a?(String)
    
    begin
      message = @manager.add_book(params[:isbn], params[:title], params[:author_last], params[:author_first], params[:subject])
    rescue DataMapper::SaveFailureError
      message = 'There was an error while saving (are you sure you provided the proper parameters?)'
    end

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      generate_response(true, [], '')
    end
  end

  # Remove a book from the library
  delete '/books' do
    # TODO: User validation?
    begin
      message = @manager.delete_book(params[:isbn])
    rescue DataMapper::ImmutableDeletedError => e
      puts "#{e}"
      message = 'There was an error while deleting - check log files for more information'
    end

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      generate_response(true, [], '')
    end
  end

  # Let the service know a book is being checked out
  post '/checkout' do
    # TODO: User validation?
  end

  # Let the service know a book is being checked in
  post '/checkin' do
    # TODO: User validation?
  end

  # Submit a review on a book
  post '/review' do
  end

private

  # Helper method. Generates a response in JSON and returns it.
  def generate_response(successful, results, message)
    resp = {}
    resp['successful'] = successful
    resp['results'] = results
    resp['message'] = message
    resp.to_json
  end

  # Helper method. Returns string explaining why the params provided are invalid or true if they are valid.
  def new_book_valid_params(params)
    return 'There is a piece of information missing' unless params[:isbn] && params[:title] && params[:author_first] && params[:author_last]
    return 'There are mismatched author names' if params[:author_last].size != params[:author_first].size
    true
  end

  run! if app_file == $0 # This is mostly for debugging
end
