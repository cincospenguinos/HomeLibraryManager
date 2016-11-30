# book.rb
#
# Class representing a book.
require 'data_mapper'


class Book
  include DataMapper::Resource

  #@return [Integer] the ID for this book
  property :id, Serial

  #@return [String] the ISBN number for this book
  property :isbn, String, :required => true

  #@return [String] the title of this book
  property :title, String, :required => true

  #@return [String] the dewey decimal number of this book
  property :dewey, String, :required => false

  has n, :authors
  has n, :subjects
  has n, :reviews
  has n, :checkout_event

  # Informs whether or not the book is checked out
  # @return [Boolean] whether or not this book is checked out
  def checked_out?
    evt = CheckoutEvent.last(:book => self)
    return false unless evt
    evt.checked_out?
  end

  # Returns a hash containing just a summary of the book
  # @return [Hash] summary of the book
  def summary
    {
        :title => title,
        :authors => authors,
        :checked_out => checked_out?
    }
  end

  # Returns a hash containing all of the info of the book
  # @return [Hash] all the info of the book
  def full_info
    {
        :isbn => isbn,
        :title => title,
        :authors => authors,
        :subjects => subjects,
        :reviews => reviews
    }
  end
end
