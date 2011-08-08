require 'rubygems'
require 'bacon'
Bacon.summary_on_exit

# Helpers
F = ::File
D = ::Dir
ROOT = F.dirname(__FILE__)+'/..'
$:.unshift ROOT+'/lib'
require ROOT+'/test/db.rb'
::Sequel::Model.plugin :rack_backend_api_adapter

describe 'Sequel Adapter' do
  
  should 'Define Model#default_backend_columns' do
    Haiku.new.default_backend_columns.should==(Haiku.columns - [:id])
  end
  
  should 'Make forms for the correct action' do
    Haiku.new.backend_form('/url').should.match(/action='\/url'/)
  end
  
  should 'Make forms including the requested fields - full form' do
    haiku = Haiku.new
    full_form = haiku.backend_form('/url')
    haiku.default_backend_columns.each do |c|
      full_form.should.match(/#{Regexp.escape haiku.crushyfield(c)}/)
    end
  end
  
  should 'Make forms including the requested fields - partial form' do
    haiku = Haiku.new
    partial_form = haiku.backend_form('/url', [:title])
    partial_form.should.match(/#{Regexp.escape haiku.crushyfield(:title)}/)
    list = haiku.default_backend_columns - [:title]
    list.each do |c|
      partial_form.should.not.match(/#{Regexp.escape haiku.crushyfield(c)}/)
    end
  end
  
  should 'Have Method Override value POST/PUT automatically set by default in the form' do
    Haiku.new.backend_form('/url').should.not.match(/name='_method'/)
    Haiku.first.backend_form('/url').should.match(/name='_method' value='PUT'/)
  end
  
  should 'Not have a _destination field if the option is not used in the form' do
    Haiku.new.backend_form('/url').should.not.match(/name='_destination'/)
  end
  
  should 'Have a _destination field if the option is used in the form' do
    Haiku.new.backend_form('/url', nil, {:destination=>"/moon"}).should.match(/name='_destination' value='\/moon'/)
  end
  
  should 'Make forms with enctype automated' do
    Haiku.new.backend_form('/url').should.not.match(/enctype='multipart\/form-data'/)
    Pic.new.backend_form('/url').should.match(/enctype='multipart\/form-data'/)
  end
  
  should 'Be able to change text for the submit button of the form and keep it when validation does not pass straight away' do
    f = Haiku.new.backend_form('/url')
    f.should.match(/<input type='submit' name='save' value='SAVE' \/>/)
    f.should.not.match(/name='_submit_text'/)
    f = Haiku.new.backend_form('/url', nil, {:submit_text=>'CREATE'})
    f.should.match(/<input type='submit' name='save' value='CREATE' \/>/)
    f.should.match(/name='_submit_text' value='CREATE'/)
  end
  
  should 'Send the list of fields in the correct order' do
    # That helps keeping the same order when validation doesn't pass
    # Also it keeps fields not sent when untouched, like checkboxes or images
    Pic.new.backend_form('/url').scan(/name='fields\[\]'/).size.should==2
  end
  
  should 'Have a backend_delete_form method - pure HTTP way of deleting records with HTTP DELETE method' do
    form = Haiku.first.backend_delete_form('/url')
    form.should.match(/name='_method' value='DELETE'/)
    form.should.match(/<input type='submit' name='save' value='X' \/>/)
    form.scan(/input/).size.should==3
    form = Haiku.first.backend_delete_form('/url', {:submit_text=>'Destroy', :destination=>'/moon'})
    form.should.match(/<input type='submit' name='save' value='Destroy' \/>/)
    form.should.match(/name='_destination' value='\/moon'/)
    form.scan(/input/).size.should==4
  end
  
  should "Be able to sort entries with a list of IDs" do
    TopFive.sort([2,3,1,5,4])
    TopFive.order(:position).map(:flavour).should==['Vanilla','Chocolate','Strawberry','Apricot','Coconut']
  end
  
  should "Have an instance method called backend_show that says 'OK' by default" do
    Author[1].backend_show.should=='OK'
  end
  
  should "Have default labels for when Model#to_label is not implemented" do
    NoCrushyform.new.backend_to_label.should=='New NoCrushyform'
    NoCrushyform[1].backend_to_label.should=='NoCrushyform 1'
  end
  
  should "Have a correct form title for instances" do
    # No crushyform
    NoCrushyform.new.backend_form_title.should=='<h2>New NoCrushyform</h2>' # New
    NoCrushyform[1].backend_form_title.should=='<h2>Edit NoCrushyform 1</h2>' # Edit
    # Crushyform
    CamelCasedClass.new.backend_form_title.should=="<h2>#{CamelCasedClass.new.to_label}</h2>" # New
    TopFive[1].backend_form_title.should=="<h2>Edit #{TopFive[1].to_label}</h2>" # No label
    Author[1].backend_form_title.should=="<h2>Edit #{Author[1].to_label}</h2>" # Label
  end
  
  should 'Include title in the form' do
    Author[1].backend_form('/url').should.match(/#{Regexp.escape(Author[1].backend_form_title)}/)
  end
  
  should 'Yield the given block to populate the form fields' do
    Author[1].backend_form('/url'){|out| out << '<!-- YIELDED -->'}.should.match(/<!-- YIELDED -->/)
    Author[1].backend_form('/url', [:name]){|out|}.should.not.match(/#{Regexp.escape Author[1].crushyfield(:name)}/)
    Author[1].backend_form('/url'){|out| out << '<!-- YIELDED -->'}.should.not.match(/#{Regexp.escape(Author[1].backend_form_title)}/)
  end
  
end