require 'sequel'
::Sequel::Model.plugin :schema
::Sequel::Model.plugin :crushyform
DB = ::Sequel.sqlite

class Haiku < ::Sequel::Model
  set_schema do
    primary_key :id
    String :title, :crushyform_type=>:stash
    text :body
    Boolean :published, :default => true
    foreign_key :author_id, :authors
  end
  create_table unless table_exists?
  many_to_one :author
  def validate
    errors[:title] << "Should start with a decent char" if title.to_s!='' && title[0]<65
  end
end

class Author < ::Sequel::Model
  set_schema do
    primary_key :id
    String :name
  end
  create_table unless table_exists?
  one_to_many :haikus
end

Haiku.create( :title=>'Autumn', :body=>"Rust the ground\nFlush the branches\nReveal the trees" )
Haiku.create( :title=>'Winter', :body=>"There is snow\nIt covers you\nBut you are still the most beautiful" )
Haiku.create( :title=>'Spring', :body=>"No inspiration" )
