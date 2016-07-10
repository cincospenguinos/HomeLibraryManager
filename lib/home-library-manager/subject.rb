# borrower.rb
#
# Someone who is borrowing a book from you.
require 'data_mapper'

class Subject
  include DataMapper::Resource

  property :id, Serial
  property :subject, String, :required => true

  belongs_to :book

  def as_json(options = nil)
    super({:only => [:subject]}.merge(options || {}))
  end
end