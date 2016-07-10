# book_information_manager.rb
#
# Holy crap I suck at naming things. Acts as a layer of abstraction with the model. Provides ability to query for
# certain books, grabs all the information about a given book, etc.
require 'data_mapper'

class BookInformationManager

  def initialize
  end

  # Returns all of the books in the DB along with their various pieces of information
  def get_all_books
    all_books = []

    Book.all.each do |book|
      data = {}
      data[:book] = book
      data[:authors] = Author.all(:book => book)
      data[:subjects] = Subject.all(:book => book)

      all_books.push(data)
    end

    all_books
  end

end