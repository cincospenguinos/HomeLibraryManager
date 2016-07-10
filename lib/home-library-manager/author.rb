# author.rb
#
# Class representing an author of a boo
require 'data_mapper'

class Author
  include DataMapper::Resource

  property :id, Serial
  property :author_last, String, :required => true
  property :author_first, String, :required => true

  belongs_to :book
end
