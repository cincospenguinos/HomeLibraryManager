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

    Book.all.each do |book|
      data = {}
      data[:book] = book

      # Check the authors
      data[:authors] = Author.all(:book => book)
      next unless verify_authors(data[:authors], options[:author_last], options[:author_first])

      all_books.push(data)
    end

    all_books
  end

private

  # Helper method. Returns true if the authors array passed contains both author_last and author_first,
  # or just one of them if only one of them was provided
  def verify_authors(authors, author_last, author_first)
    true unless author_last || author_first

    authors.each do |author|
      last_name = author_last && author.last_name == author_last || !author_last
      first_name = author_first && author.first_name == author_first || !author_first

      if last_name && first_name
        return true
      end
    end

    false
  end

end