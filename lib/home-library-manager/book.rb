# book.rb
#
# Class representing a book.
class Book
  include DataMapper::Resource

  property :id, Serial
  property :isbn, String, :required => true
  property :title, String, :required => true
  property :date_checked_out, DateTime
  property :date_checked_in, DateTime

  has n, :authors
  has n, :subjects
  belongs_to :borrower
end
