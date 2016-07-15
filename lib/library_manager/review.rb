# review.rb
#
# Class representing a review for a book
require 'data_mapper'

class Review
  include DataMapper::Resource

  #@return [Integer] the ID associated with this review
  property :id, Serial

  #@return [String] the text of the review itself
  property :review_text, Text, :required => true

  #@return [DateTime] the date this review was published
  property :date, DateTime, :required => true

  #@return [String] the last name of the reviewer
  property :last_name, String, :required => true

  #@return [String] the first name of the reviewer
  property :first_name, String, :required => true

  belongs_to :book

  def as_json(options = nil)
    super({:only => [:review_text, :date, :last_name, :first_name], :include => {
        book: {:only => [:title, :isbn]}
    }}.merge(options || {}))
  end
end
