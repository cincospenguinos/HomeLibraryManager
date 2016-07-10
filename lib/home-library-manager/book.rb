# book.rb
#
# Class representing a book.
require 'data_mapper'

class Book
  include DataMapper::Resource
  #Event.raise_on_save_failure = true

  property :id, Serial
  property :isbn, String, :required => true
  property :title, String, :required => true

  has n, :authors
  has n, :subjects
  has n, :reviews
end
