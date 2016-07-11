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

    # Ensure that we have the proper options setup for the searches we are doing
    options[:subject] = [ options[:subject] ] if options[:subject] && !options[:subject].is_a?(Array)

    Book.all.each do |book|
      data = {}
      data[:book] = book

      # Check the authors
      data[:authors] = Author.all(:book => book)
      # next unless verify_authors(data[:authors], options[:author_last], options[:author_first])


      data[:subjects] = get_all_subjects(options[:subject], book)
      next unless data[:subjects]

      all_books.push(data)
    end

    all_books
  end

private

  # Helper method. Returns true if the authors array passed contains both author_last and author_first,
  # or just one of them if only one of them was provided
  def verify_authors(authors, author_last, author_first) # TODO: Multiple authors?
    true unless author_last || author_first

    authors.each do |author|
      last_name = author_last && author.last_name == author_last || !author_last
      first_name = author_first && author.first_name == author_first || !author_first

      return true if last_name && first_name
    end

    false
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

  # Helper method. Returns true if the expected subjects are all included in the subject array provided
  def verify_subjects(subjects, expected_subjects)
    true unless expected_subjects && !expected_subjects.empty?
    verified_subjects = {}

    expected_subjects.each do |sub|
      verified_subjects[sub] = false
    end

    subjects.each do |sub|
      verified_subjects[sub.subject] = true
    end

    verified_subjects.each do |sub, verify|
      return false unless verify
    end

    true
  end

end