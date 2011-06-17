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
    Haiku.new.backend_form('/url').should.match(/name='_method' value='POST'/)
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
  
  should 'Be able to change text for the submit button of the form' do
    Haiku.new.backend_form('/url').should.match(/<input type='submit' name='save' value='SAVE' \/>/)
    Haiku.new.backend_form('/url', nil, {:submit_text=>'CREATE'}).should.match(/<input type='submit' name='save' value='CREATE' \/>/)
  end
  
  should 'Have a backend_delete_form method - pure HTTP way of deleting records with HTTP DELETE method' do
    form = Haiku.first.backend_delete_form('/url')
    form.should.match(/name='_method' value='DELETE'/)
    form.should.match(/<input type='submit' name='save' value='X' \/>/)
    form.scan(/input/).size.should==2 
    form = Haiku.first.backend_delete_form('/url', {:submit_text=>'Destroy', :destination=>'/moon'})
    form.should.match(/<input type='submit' name='save' value='Destroy' \/>/)
    form.should.match(/name='_destination' value='\/moon'/)
    form.scan(/input/).size.should==3
  end
  
end