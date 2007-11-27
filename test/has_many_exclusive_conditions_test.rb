$:.unshift(File.dirname(__FILE__) + '/../lib')
$:.unshift(File.dirname(__FILE__) + '/..')

require 'test/unit'
require 'rubygems'
require 'active_record'
require 'init'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => "has_many_exclusive_conditions.sqlite3.db")

ActiveRecord::Schema.define(:version => 1) do
  create_table :users, :force => true do  |t|
    t.string  :name
    t.boolean :is_admin, :default => false
  end

  create_table :things, :force => true do |t|
    t.string  :name
    t.integer :user_id
  end
end

class User < ActiveRecord::Base
  has_many :things, :exclusive_conditions => %q(`things`.user_id = #{id} OR #{is_admin ? 1 : 0})
end

class Thing < ActiveRecord::Base
  belongs_to :user
end

class HasManyExclusiveConditionsTest < Test::Unit::TestCase

  def setup
    @alice ||= User.create :name => "Alice", :is_admin => true
    @bob   ||= User.create :name => "Bob"
    
    @alices_thing ||= Thing.create :name => "Alice's Thing", :user => @alice
    @bobs_thing   ||= Thing.create :name => "Bob's Thing",   :user => @bob
  end

  def test_admin_should_have_all_things
    assert_block { @alice.things.include?(@bobs_thing) }
    assert_block { @alice.things.include?(@alices_thing) }    
  end

  def test_user_should_have_its_things
    assert_block { @bob.things.include?(@bobs_thing) }
    assert_block { !@bob.things.include?(@alices_thing) }
  end
  
end
