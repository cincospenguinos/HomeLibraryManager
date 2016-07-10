# borrower.rb
#
# Someone who is borrowing a book from you.
class Subject
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true

  belongs_to :book
end
