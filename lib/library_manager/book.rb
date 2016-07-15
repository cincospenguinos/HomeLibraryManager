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

  def to_json(*args)
    {
      :isbn => isbn,
      :title => title,
      :authors => Author.all(:book => self),
      :subjects => Subject.all(:book => self),
      :checked_out => checked_out?
    }.to_json
  end
end
