require File.expand_path '../spec_helper', __FILE__

RSpec.describe HomeLibraryManager do

  context 'when searching for books in the library' do

    before(:all) do
      get '/' # This just starts up the DB stuff so that we can add stuff to the DB

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

    it 'returns all the books in the library when asked' do
      get '/books'

      response = JSON.parse(last_response.body)

      expect(response['results'].count).to eq(4)
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
end