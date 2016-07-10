# review.rb
#
# Class representing a review for a book
require 'data_mapper'

class Review
  include DataMapper::Resource
  
  property :id, Serial
  property :review, Text, :required => true
  property :date, DateTime, :required => true
  property :reviewer_first, String, :required => true
  property :reviewer_last, String, :required => true

  belongs_to :book
end
