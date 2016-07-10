# borrower.rb
#
# Someone borrowing a book
class Borrower
  include DataMapper::Resource

  property :id, Serial
  property :last_name, String, :required => true
  property :first_name, String, :required => true
  property :phone_number, String
  property :email_address, String
  
  has_n, :books
end
