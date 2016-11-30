# borrower.rb
#
# Someone borrowing a book
require 'data_mapper'

class Borrower
  include DataMapper::Resource

  #@return [Integer] the ID associated with the borrower (think library card number)
  property :id, Serial

  #@return [String] the last name of the borrower
  property :last_name, String, :required => true

  #@return [String] the first name of the borrower
  property :first_name, String, :required => true

  #@return [String] the phone number of the borrower
  property :phone_number, String

  #@return [String] the email address of the borrower
  property :email_address, String

  has n, :checkout_event

  # def as_json(options = nil)
  #   super({:only => [:last_name, :first_name, :date_taken, :date_returned, :phone_number, :email_address]}.merge(options || {}))
  # end
end
