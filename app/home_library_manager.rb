# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'
require 'yaml'
require 'json'

require_relative '../lib/book'
require_relative '../lib/author'
require_relative '../lib/subject'
require_relative '../lib/review'
require_relative '../lib/borrower'
require_relative '../lib/checkout_event'

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
    erb :index
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

    if params['checked_out']
      if params['checked_out'] == 'true'
        data.delete_if { |book| !Book.first(:title => book[:title]).checked_out? }
      elsif params['checked_out'] == 'false'
        data.delete_if { |book| Book.first(:title => book[:title]).checked_out? }
      else
        return send_response(false, {}, 'The parameter "checked_out" must only be "true" or "false"')
      end
    end

    send_response(true, data, '')
  end

  ## Add a book to the library
  post '/books' do
    return send_response(false, {}, 'Required parameters are missing') unless params['authors'] && params['title'] && params['isbn']
    params['authors'] = [params['authors']] unless params['authors'].is_a?(Array)

    return send_response(false, {}, 'The book provided already exists') if Book.first(:isbn => params['isbn'])

    authors = []
    params['authors'].each do |a|
      tmp = {}
      author = a.split(',')
      tmp[:last_name] = author[0]
      tmp[:first_name] = author[1] if author.size >= 2
      authors.push(tmp)
    end

    book = Book.create(:title => params['title'], :isbn => params['isbn'])

    return send_response(false, {}, 'The book was unable to be saved') unless book.saved?

    authors_created = []

    authors.each do |author|
      a = Author.create(:last_name => author[:last_name], :book => book)
      a.update(:first_name => author[:first_name]) if author[:first_name]
      unless a.saved?
        Author.all(:book => book).destroy
        book.destroy
        return send_response(false, {}, "Could not create author #{author[:last_name]}")
      end
    end

    subjects_created = []

    if params['subjects']
      params['subjects'] = [params['subjects']] unless params['subjects'].is_a?(Array)
      params['subjects'].each do |subject|
        sub = Subject.create(:subject => subject, :book => book)
        unless sub
          Author.all(:book => book).destroy
          book.destroy
          return send_response(false, {}, "Could not create subject #{subject}")
        end
      end
    end

    send_response(true, {}, '')
  end

  ## Modify something to a book that already exists in the library
  put '/books' do
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
