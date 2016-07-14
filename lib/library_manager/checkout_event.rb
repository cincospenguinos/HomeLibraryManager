# checkout_event.rb
#
# Represents a time when a given book was checked out by someone.
require 'data_mapper'

class CheckoutEvent
  include DataMapper::Resource

  property :id, Serial
  property :date_taken, DateTime, :required => true
  property :date_returned, DateTime

  belongs_to :borrower
  belongs_to :book

  def as_json(options  = nil)
    super({:only => [:date_taken, :date_returned]}.merge(options || {}))
  end
end