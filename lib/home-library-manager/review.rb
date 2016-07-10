# review.rb
#
# Class representing a review for a book
class Review
  include DataMapper::Resource
  
  property :isbn, String, :required => true
  property :review, Text, :required => true
  property :date, DateTime, :required => true

  belongs_to :book
end
