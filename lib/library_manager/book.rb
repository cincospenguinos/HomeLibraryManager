# book.rb
#
# Class representing a book.
require 'data_mapper'

class Book
  include DataMapper::Resource

  property :id, Serial
  property :isbn, String, :required => true
  property :title, String, :required => true

  has n, :authors
  has n, :subjects
  has n, :reviews
  has n, :checkout_event

  # Returns true if the book is currently checked out
  def checked_out?
    evt = CheckoutEvent.last(:book => self)
    return true unless !evt || evt.attribute_get(:date_returned)
    false
  end

  def as_json(options = nil)
    super({:only => [:isbn, :title]}.merge(options || {}))
  end
end
