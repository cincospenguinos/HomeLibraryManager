require File.expand_path '../spec_helper', __FILE__

RSpec.describe HomeLibraryManager do

  before(:all) do
    @config = YAML.load(File.read('library_config.yml'))[:test]
    db_config = @config[:database]
    data_mapper_config = @config[:data_mapper]
    DataMapper.setup(:default, "#{db_config[:db_engine]}://#{db_config[:db_user]}:#{db_config[:db_password]}@#{db_config[:db_hostname]}/#{db_config[:db_name]}")

    if data_mapper_config[:logger_std_out]
      DataMapper::Logger.new($stdout, :debug, '[DataMapper]') # for debugging
    end

    DataMapper::Model.raise_on_save_failure = data_mapper_config[:raise_on_save_failure]
    DataMapper.finalize
    DataMapper.auto_migrate!
    destroy_all
  end

  context 'when searching for books in the library' do

    before(:all) do
      book = Book.create!(:isbn => '9780671212094', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)

      book = Book.create!(:isbn => '9780679734529', :title => 'Notes from Underground')
      Author.create!(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Literature', :book => book)
      Review.create!(:last_name => 'Doe', :first_name => 'Jane', :date => DateTime.now, :book => book, :review_text => 'It was good.')

      book = Book.create!(:isbn => '9781593082444', :title => 'Utopia')
      Author.create!(:last_name => 'More', :first_name => 'Thomas', :book => book)
      Subject.create!(:subject => 'Philosophy', :book => book)

      book = Book.create!(:isbn => '9780743477123', :title => 'Hamlet')
      Author.create!(:last_name => 'Shakespeare', :first_name => 'William', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Theatre', :book => book)
      borrower = Borrower.create!(:last_name => 'Doe', :first_name => 'John')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:all) do
        destroy_all
    end

    it 'returns all the books in the library' do
      get '/books'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(4)
    end

    it 'returns all the full information on the books in the library' do
      get '/books?summary=false'

      response = JSON.parse(last_response.body)

      # TODO: Expectations
    end

    it 'returns all books matching a given title when asked' do
      get '/books?title=Notes from Underground'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(1)
      expect(response['results'][0]['authors'][0]['last_name']).to eq('Dostoevsky')
    end

    it 'returns books written by a specific author when asked' do
      get '/books?last_name=Dostoevsky'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(1)
      expect(response['results'][0]['authors'][0]['last_name']).to eq('Dostoevsky')
      expect(response['results'][0]['authors'][0]['first_name']).to eq('Fyodor')
    end

    it 'returns all books that belong to a specific subject when asked' do
      get '/books?subject=Philosophy&summary=false'

      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['subjects'].include?({'subject' => 'Philosophy'})).to eq true
    end

    it 'returns all books that belong to all subjects provided when asked' do
      get '/books?subject[]=Fiction&subject[]=Literature'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(1)
      expect(result[0]['title']).to eq('Notes from Underground')
      expect(result[0]['authors'][0]['last_name']).to eq ('Dostoevsky')
    end

    it 'returns all books that belong to all subjects provided and have the last name provided' do
      get '/books?subject[]=Fiction&subject[]=Literature&last_name=Dostoevsky'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(1)
      expect(result[0]['title']).to eq('Notes from Underground')
      expect(result[0]['authors'][0]['last_name']).to eq ('Dostoevsky')
    end

    it 'returns all books that match a given ISBN number' do
      get '/books?isbn=9780671212094'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(1)
      expect(result[0]['title']).to eq('How to Read a Book')
    end

    it 'returns no books when the provided parameters do not match any books' do
      get '/books?last_name=FOOBAR'

      result = JSON.parse(last_response.body)['results']

      expect(result.count).to eq(0)
    end

    it 'returns all books that are checked out when requested' do
      get '/books?checked_out=true'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(1)
      expect(result[0]['title']).to eq('Hamlet')
      expect(result[0]['authors'][0]['last_name']).to eq('Shakespeare')
    end

    it 'returns all books that are checked in when requested' do
      get '/books?checked_out=false'

      result = JSON.parse(last_response.body)['results']
      expect(result.count).to eq(3)
    end

    it 'returns all books that have been checked out but are now checked in' do
      post '/checkin?last_name=Doe&first_name=John&isbn=9780743477123'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=Hamlet&checked_out=false'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['isbn']).to eq('9780743477123')
    end

    it 'informs me when I give it an incorrect value for checked_out' do
      get '/books?checked_out=foo'
      response = JSON.parse(last_response.body)

      expect(response['successful']).to be_falsey
    end
  end

  context 'when adding books to the library' do

    after(:each) do
      destroy_all
    end

    it 'adds a book when the proper information is provided' do
      post '/books?title=The Sun Also Rises&isbn=9780743297332&authors[]=Hemmingway,Ernest'
      expect(JSON.parse(last_response.body)['successful']).to be_truthy
      get '/books?title=The Sun Also Rises'

      results = JSON.parse(last_response.body)['results']
      expect(results[0]['title']).to eq('The Sun Also Rises')
    end

    it 'returns a message when there is not enough information to add a book' do
      post '/books?title=herp&authors[]=derp,'

      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'adds a book with multiple authors are given' do
      post '/books?isbn=9780671212094&title=How to Read a Book&authors[]=Adler,Mortimer&authors[]=Van Doren,Charles'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?isbn=9780671212094'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['title']).to eq('How to Read a Book')
      expect(results[0]['authors'].count).to eq(2)
    end

    it 'adds a book with subjects' do
      post '/books?isbn=9780671212094&title=How to Read a Book&authors[]=Adler,Mortimer&authors[]=Van Doren,Charles&subjects[]=non-fiction'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?isbn=9780671212094&summary=false'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(1)
      expect(results[0]['subjects']).to include({'subject' => 'non-fiction'})
    end
  end

  context 'when modifying books in the library' do

    before(:each) do
      book = Book.create!(:isbn => '9780671212094', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)

      book = Book.create!(:isbn => '9780679734529', :title => 'Notes from Underground')
      Author.create!(:last_name => 'Dostoevsky', :first_name => 'Fyodor', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Literature', :book => book)
      Review.create!(:last_name => 'Doe', :first_name => 'Jane', :date => DateTime.now, :book => book, :review_text => 'It was good.')

      book = Book.create!(:isbn => '9781593082444', :title => 'Utopia')
      Author.create!(:last_name => 'More', :first_name => 'Thomas', :book => book)
      Subject.create!(:subject => 'Philosophy', :book => book)

      book = Book.create!(:isbn => '9780743477123', :title => 'Hamlet')
      Author.create!(:last_name => 'Shakespeare', :first_name => 'William', :book => book)
      Subject.create!(:subject => 'Fiction', :book => book)
      Subject.create!(:subject => 'Theatre', :book => book)
      borrower = Borrower.create!(:last_name => 'Doe', :first_name => 'John')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:each) do
      destroy_all
    end

    it 'allows me to add a subject' do
      put '/books?isbn=9781593082444&subjects[]=Fiction'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?isbn=9781593082444&summary=false'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      results = response['results']
      expect(results[0]['subjects']).to include({'subject' => 'Fiction'})
    end

    it 'does nothing if the book does not exist' do
      put '/books?isbn=191919191&authors[]=Cool,Joe'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'does not add a subject twice' do
      put '/books?isbn=9781593082444&subjects[]=Philosophy'
      get '/books?isbn=9781593082444&summary=false'
      results = JSON.parse(last_response.body)['results']
      expect(results[0]['subjects'].size).to eq(1)
    end

    it 'allows me to remove a subject' do
      put '/books?isbn=9781593082444&subjects[]=Philosophy&remove=true'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy
    end

    it 'allows me to add an author' do
      put '/books?isbn=9781593082444&authors[]=Dude,Some'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      expect(Author.all(:book => {:isbn => '9781593082444'}).size).to eq(2)
    end

    it 'does not add an author twice' do
      put '/books?isbn=9781593082444&authors[]=More,Thomas'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      expect(Author.all(:book => {:isbn => '9781593082444'}).size).to eq(1)
    end
  end

  context 'when deleting books from the library' do

    after(:each) do
      destroy_all
    end

    it 'deletes a book when given an isbn number' do
      post '/books?isbn=9780671212094&title=How to Read a Book&author_last=Adler&author_first=Mortimer'
      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(1)

      delete '/books?isbn=9780671212094'
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
      Review.create!(:first_name => 'Joe', :last_name => 'Doug', :review_text => 'This book was good.', :date => DateTime.now, :book => book)

      delete '/books?isbn=978-0-671-21209-4'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?title=How to Read a Book'
      results = JSON.parse(last_response.body)['results']
      expect(results.size).to eq(0)
    end

    it 'deletes multiple books at a time' do
      # get '/books'
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

  context 'when checking out a book from the library' do
    before(:each) do
      book = Book.create!(:isbn => '978-0-7432-9733-2', :title => 'The Sun Also Rises')
      Author.create!(:last_name => 'Hemingway', :first_name => 'Ernest', :book => book)
    end

    after(:each) do
      CheckoutEvent.all.destroy!
      Author.all.destroy!
      Book.all.destroy!
    end

    after(:all) do
      destroy_all
    end

    it 'checks out a book on the current date and time when given the proper information' do
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['isbn']).to eq('978-0-7432-9733-2')
    end

    it 'checks out a book and includes the email address and phone number of the person provided' do
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2&email_address=john@doe.org&phone_number=KL5-3226'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(1)
      expect(results[0]['isbn']).to eq('978-0-7432-9733-2')

      get '/checkout?last_name=Doe'
      results = JSON.parse(last_response.body)['results']

      expect(results.count).to eq(1)
      expect(results[0]['books'][0]['isbn']).to eq('978-0-7432-9733-2')
      expect(results[0]['borrower']['last_name']).to eq('Doe')
      expect(results[0]['borrower']['first_name']).to eq('John')
      expect(results[0]['borrower']['email_address']).to eq('john@doe.org')
      expect(results[0]['borrower']['phone_number']).to eq('KL5-3226')
    end

    it 'does not check out a book given incomplete parameters' do
      post '/checkout?last_name=Doe&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey

      post '/checkout?first_name=Jane&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'does not check out a book I do not own' do
      post '/checkout?last_name=Doe&first_name=Jane&isbn=97-0450-362-8'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'does not check out a book that is already checked out' do
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'does not complete a transaction if a book that is already checked out is requested to be checked out again' do
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)

      post '/checkout?last_name=Doe&first_name=John&isbn=978-0-7432-9733-2'
      post '/checkout?last_name=Doe&first_name=John&isbn[]=978-0-7432-9733-2&isbn[]=978-0-7434-7712-3'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end
  end

  context 'when checking in a book from the library' do

    before(:all) do
      book = Book.create!(:isbn => '978-0-7432-9733-2', :title => 'The Sun Also Rises')
      Author.create!(:last_name => 'Hemingway', :first_name => 'Ernest', :book => book)
      borrower = Borrower.create!(:last_name => 'Herb', :first_name => 'Derb')

      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Theory', :book => book)
    end

    after(:all) do
      destroy_all
    end

    before(:each) do
      book = Book.first(:isbn => '978-0-7432-9733-2')
      borrower = Borrower.first(:last_name => 'Herb')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
    end

    after(:each) do
      CheckoutEvent.all.destroy!
    end

    it 'informs me when I give it an incorrect value for some parameter' do
      post '/checkin?last_name=Herb&first_name=Derb'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'lets me check in a book given the correct information' do
      post '/checkin?last_name=Herb&first_name=Derb&isbn=978-0-7432-9733-2'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(0)
    end

    it 'does not check in a book that I do not own' do
      post '/checkin?last_name=Herb&first_name=Derb&isbn=978-0-679-73452-9'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'does not check in a book that the person provided did not check out' do
      post '/checkin?last_name=Herb&first_name=Derb&isbn=97-0757-276-0'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_falsey
    end

    it 'permits multiple books to be checked in at once' do
      post '/books?author_last=Bologna&author_first=Bologna&isbn=97-0757-276-0&title=Complete Bullshilogna for Dummies'
      post '/checkout?last_name=Herb&first_name=Derb&isbn=97-0757-276-0'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy
      post '/checkin?last_name=Herb&first_name=Derb&isbn[]=978-0-7432-9733-2&isbn[]=978-0-671-21209-4&isbn[]=97-0757-276-0'
      response = JSON.parse(last_response.body)
      expect(response['successful']).to be_truthy

      get '/books?checked_out=true'
      results = JSON.parse(last_response.body)['results']
      expect(results.count).to eq(0)
    end

  end

  context 'when browsing who has books checked out from the library' do
    before(:all) do
      destroy_all
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

    after(:all) do
      destroy_all
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

  context 'when submitting a review for a book' do

    before(:all) do
      destroy_all
      book = Book.create!(:isbn => '978-0-671-21209-4', :title => 'How to Read a Book')
      Author.create!(:last_name => 'Adler', :first_name => 'Mortimer', :book => book)
      Author.create!(:last_name => 'Van Doren', :first_name => 'Charles', :book => book)
      borrower = Borrower.create!(:last_name => 'Roch', :first_name => 'Mike')
      CheckoutEvent.create!(:date_taken => DateTime.now, :borrower => borrower, :book => book)
      Subject.create!(:subject => 'Non-Fiction', :book => book)
      Subject.create!(:subject => 'Literary Studies', :book => book)

      @review = {}
      @review[:last] = 'Doe'
      @review[:first] = 'Jane'
      @review[:review_text] = "It was pretty good."
      @review[:isbn] = '978-0-671-21209-4'
    end

    after(:each) do
      Review.all.destroy!
    end

    after(:all) do
      destroy_all
    end

    it 'saves a review when handed the proper information' do
      post "/reviews?last_name=#{@review[:last]}&first_name=#{@review[:first]}&review_text=#{@review[:review_text]}&isbn=#{@review[:isbn]}"
      herp = JSON.parse(last_response.body)
      expect(JSON.parse(last_response.body)['successful']).to be_truthy
      get "/books?isbn=#{@review[:isbn]}"
      expect(JSON.parse(last_response.body)['results'].count).to eq(1)
    end

    it 'does not save a review for a book that is not in the library' do
      post "/reviews?last_name=#{@review[:last]}&first_name=#{@review[:first]}&review_text=#{@review[:review_text]}&isbn=978-0-679-73452-9"
      expect(JSON.parse(last_response.body)['successful']).to be_falsey
      get "/books?isbn=978-0-679-73452-9"
      expect(JSON.parse(last_response.body)['results'].count).to eq(0)
    end
  end

  # Helper method. Destroys all the things.
  def destroy_all
    CheckoutEvent.all.destroy!
    Borrower.all.destroy!
    Review.all.destroy!
    Subject.all.destroy!
    Author.all.destroy!
    Book.all.destroy!
  end
end