require File.expand_path '../spec_helper', __FILE__

RSpec.describe HomeLibraryManager do

  before(:all) do
    get '/' # This ensures that the DB is initialized and running properly
  end

  context 'when searching for books in the library' do

    before(:all) do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      author = Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      author = Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)

      book = Book.create!(:isbn => '978-0-679-73452-9', :title => 'Notes from Underground')
      author = Author.create!(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Literature', :book => book)

      book = Book.create!(:isbn => '978-1-59308-244-4', :title => 'Utopia')
      author = Author.create!(:last_name => 'More', :first_name => 'Thomas', :book => book)
      Subject.create!(:subject => 'Philosophy', :book => book)

      book = Book.create!(:isbn => '978-0-7434-7712-3', :title => 'Hamlet')
      author = Author.create!(:last_name => 'Shakespeare', :first_name => 'William', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Theatre', :book => book)
      Borrower.create!(:last_name => 'Doe', :first_name => 'John', :date_taken => DateTime.now, :book => book)
    end

    after(:all) do
      begin
        Author.all.destroy!
        Subject.all.destroy!
        Borrower.all.destroy!
        Review.all.destroy!
        Book.all.destroy!
      rescue Error => e
        puts "#{e}"
        exit 1
      end
    end

    it 'returns all the books in the library when asked' do
      get '/books'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(4)
    end

    it 'returns all books matching a given title when asked' do
      get '/books?title=Notes from Underground'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(1)
      expect(response['results'][0]['authors'][0]['last_name']).to eq('Dostoevsky')
    end

    it 'returns books written by a specific author when asked' do
      get '/books?author_last=Dostoevsky'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(1)
      expect(response['results'][0]['authors'][0]['last_name']).to eq('Dostoevsky')
      expect(response['results'][0]['authors'][0]['first_name']).to eq('Fyodor')
    end

    it 'returns all books that belong to a specific subject when asked' do
      get '/books?subject=Philosophy'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['subjects'].include?({'subject' => 'Philosophy'})).to be true
    end

    it 'returns all books that belong to all subjects provided when asked' do
      get '/books?subject[]=Fiction&subject[]=Literature'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(1)
      expect(result[0]['book']['title']).to eq('Notes from Underground')
      expect(result[0]['authors'][0]['last_name']).to eq ('Dostoevsky')
    end

    it 'returns all books that belong to all subjects provided and have the last name provided' do
      get '/books?subject[]=Fiction&subject[]=Literature&author_last=Dostoevsky'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(1)
      expect(result[0]['book']['title']).to eq('Notes from Underground')
      expect(result[0]['authors'][0]['last_name']).to eq ('Dostoevsky')
    end

    it 'returns no books when the provided parameters do not match any books' do
      get '/books?author_first=FOOBAR'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(0)
    end

    it 'returns all books that are checked out when requested' do
      get '/books?checked_out=true'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(1)
      expect(result[0]['book']['title']).to eq('Hamlet')
      expect(result[0]['authors'][0]['last_name']).to eq ('Shakespeare')
    end

    it 'returns all books that are checked in when requested' do
      get '/books?checked_out=false'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(3)
    end
  end

  context 'when adding books to the library' do

    after(:each) do
      begin
        Author.all.destroy!
        Subject.all.destroy!
        Borrower.all.destroy!
        Review.all.destroy!
        Book.all.destroy!
      rescue Error => e
        puts "#{e}"
        exit 1
      end
    end

    it 'adds a book when the proper information is provided' do
      post '/books?title=The Sun Also Rises&isbn=978-0-7432-9733-2&author_last=Hemingway&author_first=Ernest'

      get '/books?title=The Sun Also Rises'

      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['book']['title']).to eq('The Sun Also Rises')
      expect(results[0]['authors'][0]['last_name']).to eq('Hemingway')
    end

    it 'adds a book with a given subject when the proper information is provided' do
      post '/books?title=Notes from Underground&isbn=978-0-679-73452-9&author_last=Dostoevsky&author_first=Fyodor&subject=Fiction'

      expect(JSON.parse(last_response.body)['successful']).to be_truthy

      get '/books?author_last=Dostoevsky'

      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['book']['title']).to eq('Notes from Underground')
      expect(results[0]['authors'][0]['last_name']).to eq('Dostoevsky')
    end

    it 'adds a book with multiple subjects when the proper information is provided' do
      post '/books?isbn=978-0-7434-7712-3&title=Hamlet&author_last=Shakespeare&author_first=William&subject[]=Fiction&subject[]=Literature'

      response = JSON.parse(last_response.body)

      expect(response['successful']).to be_truthy

      get '/books?author_last=Shakespeare'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['book']['title']).to eq('Hamlet')
      expect(results[0]['authors'][0]['last_name']).to eq('Shakespeare')
    end

    it 'returns a message when there is not enough information to add a book' do
      post '/books?title=herp&author_last=derp'

      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'adds a book with multiple authors are given' do
      post '/books?isbn=978-0-671-21209-4&title=How to Read a Book&author_last[]=Adler&author_first[]=Mortimer&author_last[]=Van Doren&author_first[]=Charles'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['book']['title']).to eq('How to Read a Book')
      expect(results[0]['authors'].count).to eq(2)
    end
  end

  context 'when deleting books from the library' do
    it 'deletes a book when given an isbn number' do
      post '/books?isbn=978-0-671-21209-4&title=How to Read a Book&author_last=Adler&author_first=Mortimer'
      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(1)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book with its author when given an isbn number' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book with all of its authors when it has multiple authors' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book with a subject on it' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book with more than one subject on it' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Studies', :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book even if it is checked out' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Borrower.create!(:last_name => 'Roch', :first_name => 'Mike', :date_taken => DateTime.now, :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes a book with a whole lot of information on it' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Borrower.create!(:last_name => 'Roch', :first_name => 'Mike', :date_taken => DateTime.now, :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Studies', :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end
  end

  context 'when checking a book out from the library' do
    before(:each) do
      book = Book.create!(:isbn => '978-0-7432-9733-2', :title => 'The Sun Also Rises')
      Author.create!(:last_name => 'Hemingway', :first_name => 'Ernest', :book => book)
    end

    after(:each) do
      begin
        Author.all.destroy!
        Subject.all.destroy!
        Borrower.all.destroy!
        Review.all.destroy!
        Book.all.destroy!
      rescue Error => e
        puts "#{e}"
        exit 1
      end
    end

    it 'checks out a book on the current date and time when given the proper information' do
      # post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      # response = JSON.parse(last_response.body)
      # expect(response['successful']).to be_truthy
      #
      # get '/books?checked_out=true'
      # results = JSON.parse(last_response.body)['results']
      # expect(results.count).to be(1)
      # expect(results[0]['book']['isbn']).to be('978-0-7432-9733-2')
    end
  end
end