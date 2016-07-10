# author.rb
#
# Class representing an author of a boo
require 'data_mapper'

class Author
  include DataMapper::Resource

  property :id, Serial
  property :last_name, String, :required => true
  property :first_name, String, :required => true

  belongs_to :book

  # Overrides as_json to ensure that we only return non-id information
  def as_json(options = nil)
    super({:only => [:last_name, :first_name]}.merge(options || {}))
  end
end
