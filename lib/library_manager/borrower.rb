# borrower.rb
#
# Someone borrowing a book
require 'data_mapper'

class Borrower
  include DataMapper::Resource

  property :id, Serial
  property :last_name, String, :required => true
  property :first_name, String, :required => true
  property :phone_number, String
  property :email_address, String
  property :date_taken, DateTime, :required => true
  property :date_returned, DateTime

  belongs_to :book

  def as_json
    super({:only => [:last_name, :first_name, :date_taken, :date_returned, :phone_number, :email_address]}.merge(options || {}))
  end
end
