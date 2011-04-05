require 'sequel'
::Sequel::Model.plugin :schema
DB = ::Sequel.sqlite

class Haiku < ::Sequel::Model
  set_schema do
    primary_key :id
    String :title
    text :body
    Boolean :published, :default => true
  end
  create_table unless table_exists?
  def validate
    errors[:title] << "Should start with a decent char" if title.to_s!='' && title[0]<65
  end
end

Haiku.create( :title=>'Autumn', :body=>"Rust the ground\nFlush the branches\nReveal the trees" )
Haiku.create( :title=>'Winter', :body=>"There is snow\nIt covers you\nBut you are still the most beautiful" )
Haiku.create( :title=>'Spring', :body=>"No inspiration" )
