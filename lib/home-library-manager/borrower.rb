# borrower.rb
#
# Someone borrowing a book
require 'data_mapper'

class Borrower
  include DataMapper::Resource

  property :id, Serial
  property :isbn, String, :required => true
  property :last_name, String, :required => true
  property :first_name, String, :required => true
  property :phone_number, String
  property :email_address, String
  property :date_taken, DateTime
  property :date_returned, DateTime
end
