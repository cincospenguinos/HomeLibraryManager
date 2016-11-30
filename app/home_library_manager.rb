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
  # TODO: Defend against code injection attacks

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
    return send_response(false, {}, 'No isbn was provided') unless params['isbn']
    book = Book.first(:isbn => params['isbn'])
    return send_response(false, {}, 'No book with that isbn exists in the library') unless book
    remove = params['remove'] && params['remove'] == 'true'

    if params['authors']
      params['authors'] = [params['authors']] unless params['authors'].is_a?(Array)
      authors = []

      params['authors'].each do |author|
        tmp = {}
        a = author.split(',')
        tmp[:last_name] = a[0]
        tmp[:first_name] = a[1] if a.size >= 2
        authors.push(tmp)
      end

      if remove
        authors.each do |author|
          a = Author.all(:last_name => author[:last_name], :book => book)
          a = a.all(:first_name => author[:first_name]) if author[:first_name]
          a.destroy
        end
      else
        authors.each do |author|
          a = Author.first_or_create(:last_name => author[:last_name], :book => book)
          a.update(:first_name => author[:first_name]) if author[:first_name]
        end
      end
    end

    if params['subjects']
      params['subjects'] = [params['subjects']] unless params['subjects'].is_a?(Array)

      params['subjects'].each do |s|
        if remove
          Subject.all(:subject => s, :book => book).destroy
        else
          Subject.first_or_create(:subject => s, :book => book)
        end
      end
    end

    send_response(true, {}, '')
  end

  ## Remove a book from the library
  delete '/books' do
    return send_response(false, {}, 'ISBN is a necessary parameter') unless params['isbns']
    params['isbns'] = [params['isbns']] unless params['isbns'].is_a?(Array)

    params['isbns'].each do |isbn|
      book = Book.first(:isbn => isbn)
      next unless book
      Author.all(:book => book).destroy
      Subject.all(:book => book).destroy
      Review.all(:book => book).destroy
      CheckoutEvent.all(:book => book).destroy
      book.destroy
    end

    send_response(true, {}, '')
  end

  ## Browse who has checked out what books
  get '/checkout' do
    borrowers = Borrower.all

    if params['last_name']
      params['last_name'] = [params['last_name']] unless params['last_name'].is_a?(Array)

      params['last_name'].each do |last_name|
        borrowers = borrowers.all(:last_name => last_name)
      end
    end

    if params['first_name']
      params['first_name'] = [params['first_name']] unless params['first_name'].is_a?(Array)

      params['first_name'].each do |first_name|
        borrowers = borrowers.all(:first_name => first_name)
      end
    end

    results = []

    borrowers.each do |borrower|
      tmp = {}
      books = []
      Book.all(:checkout_event => {:borrower => borrower}).each { |book| books.push(book.summary) if book.checked_out? }
      tmp[:borrower] = borrower
      tmp[:books] = books
      results.push(tmp)
    end

    send_response(true, results, '')
  end

  # Let the service know a book is being checked out
  post '/checkout' do
    return send_response(false, {}, 'One or more parameters were missing') unless params['isbn'] && params['last_name'] && params['first_name']

    book = Book.first(:isbn => params['isbn'])
    return send_response(false, {}, 'There is no book in the library with that ISBN') unless book
    return send_response(false, {}, 'That book is currently checked out') if book.checked_out?

    borrower = Borrower.first_or_create(:last_name => params['last_name'], :first_name => params['first_name'])

    borrower.update(:phone_number => params['phone_number']) if params['phone_number'] && borrower.phone_number.nil?
    borrower.update(:email_address => params['email_address']) if params['email_address'] && borrower.email_address.nil?

    evt = CheckoutEvent.create(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    return send_response(false, {}, 'Event could not be created') unless evt
    send_response(true, {}, '')
  end

  # Let the service know a book is being checked in
  post '/checkin' do
    return send_response(false, {}, 'No ISBN was provided') unless params['isbns']
    params['isbns'] = [params['isbns']] unless params['isbns'].is_a?(Array)

    params['isbns'].each do |isbn|
      evt = CheckoutEvent.first(:book => {:isbn => isbn})
      return send_response(false, {}, "No book with ISBN #{isbn} has been checked out") unless evt
      evt.check_in
    end

    send_response(true, {}, '')
  end

  # Submit a review on a book
  post '/reviews' do
    # TODO: This
  end

end
