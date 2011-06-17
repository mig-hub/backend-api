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
  
end