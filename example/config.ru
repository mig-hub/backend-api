#!/usr/bin/env rackup

::Dir.chdir(::File.dirname(__FILE__)+'/..')
$:.unshift './lib'
require 'rubygems'
require 'test/db'
require 'backend_api'
require 'example/basic_admin'

use ::Rack::ContentLength
map '/' do
  run proc{ |env|
    [200,{'Content-Type'=>'text/html'}, ["Here is the Front-end. Real action is in: <a href='/admin'>/admin</a>."]]
  }
end

map '/admin' do
  use ::Rack::Config do |env|
    env['basic_admin.models'] = [:Author, :Haiku]
  end
  use BackendAPI
  run ::Rack::Builder.app(&BASIC_ADMIN)
end