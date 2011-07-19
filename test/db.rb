require 'sequel'
::Sequel::Model.plugin :schema
::Sequel::Model.plugin :crushyform rescue nil
DB = ::Sequel.sqlite

class Haiku < ::Sequel::Model
  set_schema do
    primary_key :id
    String :title
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
    String :name, :crushyform=>{:required=>true}
    String :surname, :crushyform=>{:required=>true}
  end
  create_table unless table_exists?
  one_to_many :haikus
  def validate
    errors[:name] << 'Cannot be blank' if name.to_s==''
    errors[:surname] << 'Cannot be blank' if surname.to_s==''
  end
end

class Pic < ::Sequel::Model
  set_schema do
    primary_key :id
    String :image, :crushyform=>{:type=>:attachment}
  end
  create_table unless table_exists?
end

class CamelCasedClass < ::Sequel::Model
  set_schema do
    primary_key :id
    String :name
  end
  create_table unless table_exists?
end

Haiku.create( :title=>'Autumn', :body=>"Rust the ground\nFlush the branches\nReveal the trees" )
Haiku.create( :title=>'Winter', :body=>"There is snow\nIt covers you\nBut you are still the most beautiful" )
Haiku.create( :title=>'Spring', :body=>"No inspiration" )

Author.create(:name=>'Ray',:surname=>'Bradbury')
Author.create(:name=>'Jorge Luis',:surname=>'Borges')
Author.create(:name=>'Yasunari', :surname=>'Kawabata')
