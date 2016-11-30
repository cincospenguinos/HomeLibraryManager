require File.expand_path '../spec_helper', __FILE__

RSpec.describe Book do
  context 'when checking to see if the book is checked out' do
    before(:all) do
      db_config = YAML.load(File.read('library_config.yml'))[:test][:database]
      DataMapper.setup(:default, "#{db_config[:db_engine]}://#{db_config[:db_user]}:#{db_config[:db_password]}@#{db_config[:db_hostname]}/#{db_config[:db_name]}")
      DataMapper::Model.raise_on_save_failure = true
      DataMapper.auto_migrate!

      @book1 = Book.create!(:title => 'Notes from Underground', :isbn => '978-0-679-73452-9')
      borrower = Borrower.create!(:last_name => 'Doe', :first_name => 'John')
      CheckoutEvent.create!(:date_taken => DateTime.now, :book => @book1, :borrower => borrower)
      @book2 = Book.create!(:isbn => '978-1-59308-244-4', :title => 'Utopia')
    end

    after(:all) do
      CheckoutEvent.all.destroy!
      Borrower.all.destroy!
      Book.all.destroy!
    end

    it 'should indicate yes if it is' do
      expect(@book1.checked_out?).to be_truthy
    end

    it 'should indicate no if it is not' do
      expect(@book2.checked_out?).to be_falsey
    end

    it 'should indicate no if it was checked out but is no longer' do
      CheckoutEvent.update!(:book => @book1, :date_returned => DateTime.now)
      expect(@book1.checked_out?).to be_falsey
    end
  end
end
