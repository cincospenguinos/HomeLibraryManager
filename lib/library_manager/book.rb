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
  has 1, :borrower

  def as_json(options = nil)
    super({:only => [:isbn, :title]}.merge(options || {}))
  end
end
