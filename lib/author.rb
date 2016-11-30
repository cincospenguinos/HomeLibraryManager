# author.rb
#
# Class representing an author of a book
require 'data_mapper'

class Author
  include DataMapper::Resource

  #@return [Integer] the ID for this author
  property :id, Serial

  #@return [String] the last name of this author
  property :last_name, String, :required => true

  #@return [String] the first name of this author
  property :first_name, String, :required => true

  belongs_to :book

  # Overrides as_json to ensure that we only return non-id information
  def as_json(options = nil)
    super({:only => [:last_name, :first_name]}.merge(options || {}))
  end
end
