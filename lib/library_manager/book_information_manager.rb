# book_information_manager.rb
#
# Holy crap I suck at naming things. Acts as a layer of abstraction with the model. Provides ability to query for
# certain books, grabs all the information about a given book, etc.
require 'data_mapper'

class BookInformationManager

  def initialize
  end

  # Returns all of the books in the DB along with their various pieces of information
  def get_all_books(options = {})
    all_books = []

    options[:subject] = [ options[:subject] ] if options[:subject] && !options[:subject].is_a?(Array)
    options[:author_last] = [ options[:author_last] ] if options[:author_last] && !options[:author_last].is_a?(Array)
    options[:author_first] = [ options[:author_first] ] if options[:author_first] && !options[:author_first].is_a?(Array)

    Book.all.each do |book|
      data = {}
      data[:book] = book

      # Check the authors
      data[:authors] = get_all_authors(options[:author_last], options[:author_first], book)
      next unless data[:authors]

      # Check the subjects
      data[:subjects] = get_all_subjects(options[:subject], book)
      next unless data[:subjects]

      # Check if we are looking at books that are checked out or not
      next unless verify_checked_out(options[:checked_out], book)

      all_books.push(data)
    end

    all_books
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