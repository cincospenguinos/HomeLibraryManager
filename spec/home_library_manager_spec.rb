require File.expand_path '../spec_helper', __FILE__

#TODO : Fix everything

RSpec.describe HomeLibraryManager do

  before(:all) do
    get '/' # This ensures that the DB is initialized and running properly
  end

  context 'when searching for books in the library' do

    before(:all) do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)

      book = Book.create!(:isbn => '978-0-679-73452-9', :title => 'Notes from Underground')
      Author.create!(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Literature', :book => book)

      book = Book.create!(:isbn => '978-1-59308-244-4', :title => 'Utopia')
      Author.create!(:last_name => 'More', :first_name => 'Thomas', :book => book)
      Subject.create!(:subject => 'Philosophy', :book => book)

      book = Book.create!(:isbn => '978-0-7434-7712-3', :title => 'Hamlet')
      Author.create!(:last_name => 'Shakespeare', :first_name => 'William', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Theatre', :book => book)
      borrower = Borrower.create!(:last_name => 'Doe', :first_name => 'John')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:all) do
        Author.all.destroy!
        Subject.all.destroy!
        CheckoutEvent.all.destroy!
        Borrower.all.destroy!
        Review.all.destroy!
        Book.all.destroy!
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
      expect(results[0]['subjects'].include?({'subject' => 'Philosophy'})).to eq true
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

    it 'returns all books that match a given ISBN number' do
      get '/books?isbn=978-0-671-21209-4'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(1)
      expect(result[0]['book']['title']).to eq('How to Read a Book')
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
      expect(result[0]['authors'][0]['last_name']).to eq('Shakespeare')
    end

    it 'returns all books that are checked in when requested' do
      get '/books?checked_out=false'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(3)
    end

    it 'returns all books that have been checked out but are now checked in' do
      post '/checkin?last_name=Doe&first_name=John&isbn=978-0-7434-7712-3'
      get '/books?title=Hamlet&checked_out=false'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['book']['isbn']).to eq('978-0-7434-7712-3')
    end

    it 'informs me when I give it an incorrect value for checked_out' do
      get '/books?checked_out=foo'
      response = JSON.parse(last_response.body)

      expect(response['successful']).to be_falsey
    end

    it 'returns all books that match any of the given parameters when requested' do
      get '/books?author_last=Shakespeare&subject=Philosophy&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(2)
      expect(results[0]['book']['title']).to eq('Utopia')
      expect(results[1]['book']['title']).to eq('Hamlet')
    end

    it 'returns all books that match any of the given subjects when requested' do
      get '/books?subject[]=Fiction&subject[]=Philosophy&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(3)
    end

    it 'returns all books that match any of the given ISBNs' do
      get '/books?isbn[]=978-0-679-73452-9&isbn[]=978-1-59308-244-4&match=isbn'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(2)
    end

    it 'returns all books that match any of the given ISBNs and match=any' do
      get '/books?isbn[]=978-0-679-73452-9&isbn[]=978-1-59308-244-4&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(2)
    end

    it 'returns all books that match any of the given ISBNs or titles' do
      get '/books?title=Notes from Underground&isbn[]=978-1-59308-244-4&isbn[]=978-0-7434-7712-3&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(3)
    end

    it 'returns all books that match any of the given subjects or authors' do
      get '/books?author_last=More&subject=Fiction&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(3)
    end

    it 'returns all books that match any of the given authors, even when those authors are not in the library' do
      get '/books?author_last[]=More&author_first[]=Thomas&author_last[]=Donne&author_first[]=John&match=any'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
    end
  end

  context 'when adding books to the library' do

    after(:each) do
      Author.all.destroy!
      Subject.all.destroy!
      CheckoutEvent.all.destroy!
      Borrower.all.destroy!
      Review.all.destroy!
      Book.all.destroy!
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

    after(:each) do
      Author.all.destroy!
      Subject.all.destroy!
      CheckoutEvent.destroy!
      Borrower.all.destroy!
      Review.all.destroy!
      Book.all.destroy!
    end

    it 'deletes a book when given an isbn number' do
      post '/books?isbn=978-0-671-21209-4&title=How to Read a Book&author_last=Adler&author_first=Mortimer'
      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(1)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?isbn=978-0-671-21209-4'
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
      borrower = Borrower.create!(:last_name => 'Roch', :first_name => 'Mike')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)

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
      borrower = Borrower.create!(:last_name => 'Roch', :first_name => 'Mike')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Studies', :book => book)
      Review.create!(:first_name => 'Joe', :last_name => 'Doug', :review => 'This book was good.', :date => DateTime.now, :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes multiple books at a time' do
      get '/books'
      post '/books?title=How to Read a Book&author_last=Adler&author_first=Mortiemer&isbn=978-0-671-21209-4'
      post '/books?title=Notes from Underground&author_last=Dostoevsky&author_first=Fyodor&isbn=978-0-679-73452-9'

      delete '/books?isbn[]=978-0-671-21209-4&isbn[]=978-0-679-73452-9'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books'
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
      Author.all.destroy!
      Subject.all.destroy!
      CheckoutEvent.destroy!
      Borrower.all.destroy!
      Review.all.destroy!
      Book.all.destroy!
    end

    it 'checks out a book on the current date and time when given the proper information' do
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['book']['isbn']).to eq('978-0-7432-9733-2')
    end

    it 'checks out a book and includes the email address and phone number of the person provided' do
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2&email_address=john@doe.org&phone_number=KL5-3226'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['book']['isbn']).to eq('978-0-7432-9733-2')

      get '/checkout?last_name=Doe'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['books'][0]['isbn']).to eq('978-0-7432-9733-2')
      expect(results[0]['borrower']['last_name']).to eq('Doe')
      expect(results[0]['borrower']['first_name']).to eq('John')
      expect(results[0]['borrower']['email_address']).to eq('john@doe.org')
      expect(results[0]['borrower']['phone_number']).to eq('KL5-3226')
    end

    it 'checks out no book to any request that does not have the correct parameters' do
      post '/checkout?last_name=Doe&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end
  end

  context 'when checking in a book from the library' do

    before(:all) do
      book = Book.create!(:isbn => '978-0-7432-9733-2', :title => 'The Sun Also Rises')
      Author.create!(:last_name => 'Hemingway', :first_name => 'Ernest', :book => book)
      borrower = Borrower.create!(:last_name => 'Herb', :first_name => 'Derb')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:all) do
      Author.all.destroy!
      CheckoutEvent.all.destroy!
      Book.all.destroy!
      Borrower.all.destroy!
    end

    it 'informs me when I give it an incorrect value for some parameter' do
      post '/checkin?last_name=Herb&first_name=Derb'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'lets me checkin a book given the correct information' do
      post '/checkin?last_name=Herb&first_name=Derb&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(0)
    end
  end

  context 'when browsing who has books checked out from the library' do
    before(:all) do
      Author.all.destroy!
      Subject.all.destroy!
      CheckoutEvent.all.destroy!
      Book.all.destroy!
      Borrower.all.destroy!

      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)

      book = Book.create!(:isbn => '978-0-679-73452-9', :title => 'Notes from Underground')
      Author.create!(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Literature', :book => book)

      book = Book.create!(:isbn => '978-1-59308-244-4', :title => 'Utopia')
      Author.create!(:last_name => 'More', :first_name => 'Thomas', :book => book)
      Subject.create!(:subject => 'Philosophy', :book => book)

      book = Book.create!(:isbn => '978-0-7434-7712-3', :title => 'Hamlet')
      Author.create!(:last_name => 'Shakespeare', :first_name => 'William', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Theatre', :book => book)
    end

    before(:each) do
      book = Book.first(:isbn => '978-0-7434-7712-3')
      borrower = Borrower.create!(:last_name => 'Doe', :first_name => 'A. Deer')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
      book = Book.first(:title => 'Notes from Underground')
      borrower = Borrower.first_or_create(:last_name => 'Herb', :first_name => 'Derb')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:each) do
      CheckoutEvent.all.destroy!
      Borrower.all.destroy!
    end

    it 'returns a list of all the borrowers when asked' do
      get '/checkout'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(2)
      expect(results[0]['borrower']['last_name']).to eq('Doe')
      expect(results[0]['borrower']['first_name']).to eq('A. Deer')
      expect(results[0]['books'][0]['title']).to eq('Hamlet')
      expect(results[1]['borrower']['last_name']).to eq('Herb')
      expect(results[1]['borrower']['first_name']).to eq('Derb')
      expect(results[1]['books'][0]['title']).to eq('Notes from Underground')
    end

    it 'returns a list of all the borrowers that match a specific last name' do
      get '/checkout?last_name=Herb'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['borrower']['last_name']).to eq('Herb')
      expect(results[0]['borrower']['first_name']).to eq('Derb')
      expect(results[0]['books'][0]['isbn']).to eq('978-0-679-73452-9')
      expect(results[0]['books'][0]['title']).to eq('Notes from Underground')
    end

    it 'returns a list of all the borrowers that match a specific last name and first name' do
      get '/checkout?last_name=Herb&first_name=Derb'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['borrower']['last_name']).to eq('Herb')
      expect(results[0]['borrower']['first_name']).to eq('Derb')
      expect(results[0]['books'][0]['isbn']).to eq('978-0-679-73452-9')
      expect(results[0]['books'][0]['title']).to eq('Notes from Underground')
    end

    it 'does not return books from someone who has returned the book if it is being requested to return books that are checked out' do
      post '/checkin?isbn=978-0-679-73452-9&first_name=Herb&last_name=Derb'

      expect(JSON.parse(last_response.body)['successful']).to eq(false)

      get '/checkout?last_name=Derb&checked_out=true'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
    end
  end

  context 'when browsing reviews for various books' do
    # TODO: Test cases for this
  end

  context 'when submitting a review for a book' do
    # TODO: Test cases for this
  end
end