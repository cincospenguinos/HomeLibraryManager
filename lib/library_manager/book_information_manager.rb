# book_information_manager.rb
#
# Holy crap I suck at naming things. Acts as a layer of abstraction with the model. Provides ability to query for
# certain books, grabs all the information about a given book, etc.
require 'data_mapper'

# TODO: Turn all the methods into static methods? They are basically acting as such
class BookInformationManager

  # Returns all of the books in the DB along with their various pieces of information
  def get_all_books(options = {})
    selected_books = []

    Book.all.each do |book|
      data = {}
      data[:book] = book

      next unless !options[:title] || matches_all_titles?(options[:title], book)
      next unless !options[:isbn] || matches_all_isbns?(options[:isbn], book)

      data[:authors] = get_all_authors(options[:author_last], options[:author_first], book)
      next unless data[:authors]

      data[:subjects] = get_all_subjects(options[:subject], book)
      next unless data[:subjects]

      next unless options[:checked_out] == nil || checked_out_book_include?(options[:checked_out], book)

      selected_books.push(data)
    end

    selected_books
  end

  # Returns all of the books that match the options passed. Only to be called if there is a match option.
  def get_any_books(options)
    selected_books = []

    # TODO: How do we do this?

    selected_books
  end

  # Returns a string message if the given information is invalid, or true if the book was added correctly.
  def add_book(isbn, title, author_last, author_first, subjects)
    return 'All pieces of information (isbn, title, last name, first name) must be provided' unless isbn && title && author_last && author_first

    # TODO: ISBN validation?
    book = Book.create!(:title => title, :isbn => isbn)

    authors = Hash[author_last.zip(author_first.map { |last| last.include?(',') ? (last.split /, /) : last })]
    authors.each do |last_name, first_name|
      Author.create!(:last_name => last_name, :first_name => first_name, :book => book)
    end

    if subjects
      subjects = [ subjects ] unless subjects.is_a?(Array)

      subjects.each do |subject|
        sub = Subject.create!(:subject => subject, :book => book)
      end
    end

    true
  end

  # Deletes the book matching the ISBN number provided. Returns true if the book was deleted or
  # a string if the book was not deleted. TODO: Delete more than one?
  def delete_book(isbn)
    return 'An ISBN number must be provided' unless isbn

    book = Book.first(:isbn => isbn)
    return 'No book was found with that isbn' unless book

    Author.all(:book => book).destroy!
    Review.all(:book => book).destroy!
    Subject.all(:book => book).destroy!
    Borrower.all(:book => book).destroy!
    book.destroy!

    true
  end

  # Stores the fact that a book is checked out given the parameters. Defaults to the current date
  # and time if one is not provided in the options hash
  def checkout_book(last_name, first_name, isbn, options)
    book = Book.first(:isbn => isbn)
    return 'No book was found with the provided ISBN' unless book

    borrower = Borrower.create!(:last_name => last_name, :first_name => first_name, :date_taken => DateTime.now, :book => book)
    borrower.update!(:email_address => options[:email_address]) if options[:email_address]
    borrower.update!(:phone_number => options[:phone_number]) if options[:phone_number]

    true
  end

  # Checks in the book matching the isbn that was borrowed by the person with the given last_name and first_name.
  # Returns true if successful or an error message string if it was not.
  def checkin_book(last_name, first_name, isbn)
    book = Book.first(:isbn => isbn)
    return 'No book was found with the provided ISBN' unless book

    borrower = Borrower.first(:last_name => last_name, :first_name => first_name, :book => book)
    return 'That person does not have that book' unless borrower
    borrower.update!(:date_returned => DateTime.now)

    true
  end

  # Returns all of the borrowers matching the given options
  def get_all_borrowers(options)
    borrowers = []
    all = Borrower.all
    all = all.all(:last_name => options[:last_name]) if options[:last_name]
    all = all.all(:first_name => options[:first_name]) if options[:first_name]
    all = all.all(:email_address => options[:email_address]) if options[:email_address]
    all = all.all(:phone_number => options[:phone_number]) if options[:phone_number]

    all.each do |borrower|
      data = {}
      data[:borrower] = borrower
      data[:books] = Book.all(:borrower => borrower)

      borrowers.push(data)
    end

    borrowers
  end

  # TODO: This
  def get_any_borrowers(options)

  end

  private

  # Helper method. Returns all the authors associated with a given book, or false if
  # the book doesn't have all of the expected last or first names provided.
  def get_all_authors(expect_auth_last, expect_auth_first, book)
    authors = Author.all(:book => book)

    if expect_auth_last
      verify_last = {}

      expect_auth_last.each do |auth|
        verify_last[auth] = false
      end

      authors.each do |auth|
        verify_last[auth.last_name] = true
      end

      verify_last.each_value do |val|
        return false unless val
      end
    end

    if expect_auth_first
      verify_first = {}

      expect_auth_first.each do |auth|
        verify_first[auth] = false
      end

      authors.each do |auth|
        verify_first[auth.first_name] = true
      end

      verify_first.each_value do |val|
        return false unless val
      end
    end

    authors
  end

  # Helper method. Returns all the subjects associated with a given book, or false
  # if the book doesn't have all of the expected subjects provided
  def get_all_subjects(expected_subjects, book)
    subjects = Subject.all(:book => book)

    if expected_subjects
      verify = {}

      expected_subjects.each do |sub|
        verify[sub] = false
      end

      subjects.each do |sub|
        verify[sub.subject] = true
      end

      verify.each do |sub, value|
        return false unless value
      end
    end

    subjects
  end

  def matches_all_titles?(titles, book)
    add_book = true

    titles.each do |title|
      add_book = false if title != book.title
    end

    add_book
  end

  def matches_all_isbns?(isbns, book)
    add_book = true

    isbns.each do |isbn|
      add_book = false if isbn != book.isbn
    end

    add_book
  end

  def matches_any_titles?(titles, book)
    add_book = false

    titles.each do |title|
      add_book = true if title == book.title
    end

    add_book
  end

  def matches_any_isbns?(isbns, book)
    add_book = false

    isbns.each do |isbn|
      add_book = true if isbn == book.isbn
    end

    add_book
  end

  # Helper method. Returns true if given the book provided should be added to the collection that will be returned by
  # the query, given whether or not the user desires a checked out book.
  def checked_out_book_include?(want_checked_out, book)
    borrower = Borrower.last(:book => book)
    return true if !want_checked_out && !borrower
    return false if want_checked_out && !borrower

    is_checked_out = borrower.attribute_get(:date_returned) == nil

    return true if want_checked_out && is_checked_out
    return true if !want_checked_out && !is_checked_out

    false
  end
end