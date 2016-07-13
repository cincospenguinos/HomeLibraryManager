# home_library_manager.rb
#
# The actual Sinatra class. This is where the magic happens.
require 'sinatra/base'
require 'data_mapper'
require 'dm-migrations'
require 'yaml'
require 'json'

require_relative 'library_manager/book.rb'
require_relative 'library_manager/author.rb'
require_relative 'library_manager/subject.rb'
require_relative 'library_manager/review.rb'
require_relative 'library_manager/borrower.rb'
require_relative 'library_manager/book_information_manager'

class HomeLibraryManager < Sinatra::Base

  def initialize
    super
    @config = YAML.load(File.read('library_config.yml'))
    db_config = YAML.load(File.read('library_config.yml'))[:database]
    data_mapper_config = YAML.load(File.read('library_config.yml'))[:data_mapper]

    DataMapper.setup(:default, "#{db_config[:db_engine]}://#{db_config[:db_user]}:#{db_config[:db_password]}@#{db_config[:db_hostname]}/#{db_config[:db_name]}")

    if data_mapper_config[:logger_std_out]
      DataMapper::Logger.new($stdout, :debug) # for debugging
    end

    DataMapper::Model.raise_on_save_failure = data_mapper_config[:raise_on_save_failure]
    DataMapper.finalize
    DataMapper.auto_migrate!

    @manager = BookInformationManager.new
  end

  before do
    content_type 'application/json'
  end

  # Show the index file
  get '/' do
    content_type :html
    File.read(@config[:root_file])
  end

  # Run queries on current books in the library
  get '/books' do
    options = params
    params = get_books_valid_params(options)

    # puts "PARAMS: #{params}"
    # puts "OPTIONS: #{options}"

    if !params
      generate_response(true, @manager.get_all_books({}), '')
    elsif params.is_a?(String)
      generate_response(false, [], params)
    else
      if !params[:match] || params[:match].include?('all')
        generate_response(true, @manager.get_all_books(params), '')
      elsif params[:match].include?('any')
        generate_response(true, @manager.get_any_books(params), '')
      else
        generate_response(true, @manager.get_books_matching(params[:match], params), '')
      end
    end
  end

  # Add a book to the library
  post '/books' do
    # TODO: User validation?
    params.keys.each do |key|
      params[(key.to_sym rescue key) || key] = params.delete(key)
    end

    params[:author_last] = [params[:author_last]] if params[:author_last].is_a?(String)
    params[:author_first] = [params[:author_first]] if params[:author_first].is_a?(String)
    
    message = new_book_valid_params(params)
    
    generate_response(false, [], message) if message.is_a?(String)
    
    begin
      message = @manager.add_book(params[:isbn], params[:title], params[:author_last], params[:author_first], params[:subject])
    rescue DataMapper::SaveFailureError
      message = 'There was an error while saving (are you sure you provided the proper parameters?)'
    end

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      generate_response(true, [], '')
    end
  end

  # Remove a book from the library
  delete '/books' do
    # TODO: User validation?
    begin
      message = @manager.delete_book(params[:isbn])
    rescue DataMapper::ImmutableDeletedError => e
      puts "#{e}"
      message = 'There was an error while deleting - check log files for more information'
    end

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      generate_response(true, [], '')
    end
  end

  # Browse who has checked out what books
  get '/checkout' do
    # TODO: User validation necessary? If so, user validation?
    generate_response(true, @manager.get_all_borrowers(params), '')
  end

  # Let the service know a book is being checked out
  post '/checkout' do
    # TODO: User validation?
    message = checkout_checkin_params(params)

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      options = { :email_address =>  params[:email_address] }
      options[:phone_number] = params[:phone_number]
      message = @manager.checkout_book(params[:last_name], params[:first_name], params[:isbn], options)

      if message.is_a?(String)
        generate_response(false, [], message)
      else
        generate_response(true, [], '')
      end
    end
  end

  # Let the service know a book is being checked in
  post '/checkin' do
    # TODO: User validation?
    message = checkout_checkin_params(params)

    if message.is_a?(String)
      generate_response(false, [], message)
    else
      message = @manager.checkin_book(params[:last_name], params[:first_name], params[:isbn])

      if message.is_a?(String)
        generate_response(false, [], message)
      else
        generate_response(true, [], '')
      end
    end
  end

  # Browse reviews on books
  get '/reviews' do
    # TODO: Just this thing and we're pretty much done with the service (for now)
  end

  # Submit a review on a book
  post '/reviews' do
    # TODO: And this thing too
  end

private

  MATCH_OPTIONS = [:any, :all, :author_last, :author_first, :subject, :isbn, :title]

  # Helper method. Generates a response in JSON and returns it.
  def generate_response(successful, results, message)
    resp = {}
    resp['successful'] = successful
    resp['results'] = results
    resp['message'] = message
    resp.to_json
  end

  # Helper method. Checks the params provided to ensure they comply with the service. If they do not, returns
  # a string. If they do, returns a restructured version of params to better interact with the BookInformationManager
  def get_books_valid_params(params)
    return 'checked_out may only be true or false' if params[:checked_out] && !(params[:checked_out] == 'true' || params[:checked_out] == 'false')

    params = setup_params(params)

    if params[:match]
      params[:match].each do |match_type|
        return 'The provided parameter for "match" is not a supported option.' unless MATCH_OPTIONS.include?(match_type.to_sym)
      end
    end

    params
  end

  # Helper method. Ensures that the params passed have the proper form (everything is in Arrays). Returns the params
  # hash when finished.
  def setup_params(params)
    params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
    params[:subject] = [ params[:subject] ] if params[:subject] && params[:subject].is_a?(String)

    params[:author_last] = [ params[:author_last] ] if params[:author_last] && params[:author_last].is_a?(String)
    params[:author_first] = [ params[:author_first] ] if params[:author_first] && params[:author_first].is_a?(String)

    if params[:match]
      params[:match] = [ params[:match] ] if params[:match].is_a?(String)
      arr = params[:match]
      arr.map { |str| str.to_sym }
      params[:match] = arr
    end

    params[:title] = [ params[:title] ] if params[:title] && params[:title].is_a?(String)
    params[:isbn] = [ params[:isbn] ] if params[:isbn] && params[:isbn].is_a?(String)

    if params[:checked_out]
      if params[:checked_out] == 'true'
        params[:checked_out] = true
      else
        params[:checked_out] = false
      end
    end

    params
  end

  # Helper method. Returns string explaining why the params provided are invalid or true if they are valid.
  def new_book_valid_params(params)
    return 'The expected parameters are not provided' unless params[:isbn] && params[:title] && params[:author_first] && params[:author_last]
    return 'There are mismatched author names' if params[:author_last].size != params[:author_first].size
    true
  end

  # Helper method. Returns a string explaining why the params provided are invalid or true if they are valid
  def checkout_checkin_params(params)
    return 'The expected parameters are not provided' unless params[:last_name] && params[:first_name] && params[:isbn]
    true
  end

  # run! if app_file == $0 # This is mostly for debugging
end
