# subject.rb
#
# A subject of a book, i.e. Philosophy, Fiction, etc.
require 'data_mapper'

class Subject
  include DataMapper::Resource

  #@return [Integer] the ID of this subject
  property :id, Serial

  #@return [String] the subject name
  property :subject, String, :required => true

  belongs_to :book

  def as_json(options = nil)
    super({:only => [:subject]}.merge(options || {}))
  end
end
