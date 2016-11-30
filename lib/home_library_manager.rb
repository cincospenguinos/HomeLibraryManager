# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'
require 'yaml'
require 'json'

require_relative 'book'
require_relative 'author'
require_relative 'subject'
require_relative 'review'
require_relative 'borrower'
require_relative 'checkout_event'

class HomeLibraryManager < Sinatra::Base

  # TODO: Configure :prod, :dev, :test?
  # TODO: Create a client with javascript and stuff

  before do
    content_type 'application/json'
  end

  helpers do

    def send_response(successful, data, message)
      {
          :successful => successful,
          :results => data,
          :message => message
      }.to_json
    end
  end

  ## Show the index file
  get '/' do
    # TODO: Something nicer for this
    content_type :html
    File.read('index.html')
  end

  ## Run queries on current books in the library
  get '/books' do
    books = Book.all

    # Check each of the parameters
    if params['isbn']
      params['isbn'] = [params['isbn']] unless params['isbn'].is_a?(Array)

      params['isbn'].each do |isbn|
        books = books.all(:isbn => isbn)
      end
    end

    if params['last_name']
      params['last_name'] = [params['last_name']] unless params['last_name'].is_a?(Array)

      params['last_name'].each do |name|
        books = books.all(:authors => {:last_name => name})
      end
    end

    if params['subject']
      params['subject'] = [params['subject']] unless params['subject'].is_a?(Array)

      params['subject'].each do |subject|
        books = books.all(:subjects => {:subject => subject})
      end
    end

    if params['title']
      params['title'] = [params['title']] unless params['title'].is_a?(Array)

      params['title'].each do |title|
        books = books.all(:title => title)
      end
    end
    
    data = []

    if !params['summary'] || params['summary'] == 'true'
      books.each do |book|
        data.push(book.summary)
      end
    else
      books.each do |book|
        data.push(book.full_info)
      end
    end

    send_response(true, data, '')
  end

  ## Add a book to the library
  post '/books' do
    # TODO: This
  end

  # Remove a book from the library
  delete '/books' do
    # TODO: This
  end

  # Browse who has checked out what books
  get '/checkout' do
    # TODO: This
  end

  # Let the service know a book is being checked out
  post '/checkout' do
    # TODO: This
  end

  # Let the service know a book is being checked in
  post '/checkin' do
    # TODO: This
  end

  # Submit a review on a book
  post '/reviews' do
    # TODO: This
  end

end
