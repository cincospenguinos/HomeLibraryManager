# book_information_manager.rb
#
# Holy crap I suck at naming things. Acts as a layer of abstraction with the model. Provides ability to query for
# certain books, grabs all the information about a given book, etc.
require 'data_mapper'

# TODO: Turn all the methods into static methods? They are basically acting as such
class BookInformationManager

  # Returns all of the books in the DB along with their various pieces of information
  def get_all_books(options = {})
    all_books = []

    options[:subject] = [ options[:subject] ] if options[:subject] && !options[:subject].is_a?(Array)
    options[:author_last] = [ options[:author_last] ] if options[:author_last] && !options[:author_last].is_a?(Array)
    options[:author_first] = [ options[:author_first] ] if options[:author_first] && !options[:author_first].is_a?(Array)

    Book.all.each do |book|
      data = {}
      data[:book] = book

      next if options[:title] && book.title != options[:title] # TODO: Is there a better way to do all of this?

      data[:authors] = get_all_authors(options[:author_last], options[:author_first], book)
      next unless data[:authors]

      data[:subjects] = get_all_subjects(options[:subject], book)
      next unless data[:subjects]

      next unless verify_checked_out(options[:checked_out], book)

      all_books.push(data)
    end

    all_books
  end

  # Returns a string message if the given information is invalid, or true if the book was added correctly.
  def add_book(isbn, title, author_last, author_first, subjects)
    return 'All pieces of information (isbn, title, last name, first name) must be provided' unless isbn && title && author_last && author_first

    # TODO: ISBN validation?
    book = Book.create!(:title => title, :isbn => isbn)

    authors = Hash[author_last.zip(author_first.map { |last| last.include?(',') ? (last.split /, /) : last })]
    puts "AUTHORS! #{authors}"

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

  # Helper method. Returns true if we are not looking for books that are checked out, or if
  # the given book matches the checked out option (that is, the user wants all checked out
  # books and the book provided is checked out)
  def verify_checked_out(checked_out_option, book)
    true unless checked_out_option

    borrowers = Borrower.all(:book => book)

    return false if borrowers.count < 1 && checked_out_option == 'true'
    return false if borrowers.count >= 1 && checked_out_option == 'false'

    true
  end
end