# author.rb
#
# Class representing an author of a book
class Author
  include DataMapper::Resource

  property :isbn, String, :required => true
  property :author_last, String, :required => true
  property :author_first, String :required => true

  belongs_to :book
end
