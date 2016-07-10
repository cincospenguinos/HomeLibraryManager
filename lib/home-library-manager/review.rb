# review.rb
#
# Class representing a review for a book
require 'data_mapper'

class Review
  include DataMapper::Resource
  
  property :id, Serial
  property :review, Text, :required => true
  property :date, DateTime, :required => true
  property :last_name, String, :required => true
  property :first_name, String, :required => true

  belongs_to :book
end
