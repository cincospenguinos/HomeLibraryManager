# checkout_event.rb
#
# Represents a time when a given book was checked out by someone.
require 'data_mapper'

class CheckoutEvent
  include DataMapper::Resource

  #@return [Integer] the ID associated with this specific checkout event
  property :id, Serial

  #@return [DateTime] the date the associated book was checked out
  property :date_taken, DateTime, :default => DateTime.now

  #@return [DateTime] the date the associated book was returned
  property :date_returned, DateTime

  belongs_to :borrower
  belongs_to :book

  # Indicates whether or not the person associated with this event returned
  # their book
  # @return [Boolean] whether or not the book is still checked out
  def checked_out?
    self.date_returned == nil
  end

  # Checks in the book
  def check_in
    update(:date_returned => DateTime.now)
    checked_out?
  end
  
  def as_json(options  = nil)
    super({:only => [:date_taken, :date_returned]}.merge(options || {}))
  end
end
