require 'rack/test'
require 'rspec'
require 'data_mapper'
require 'coveralls'
Coveralls.wear!

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app/home_library_manager', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app() described_class end
end

RSpec.configure { |c| c.include RSpecMixin }