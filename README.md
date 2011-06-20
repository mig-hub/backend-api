BACKEND API
===========

HOW TO INSTALL
==============

This is a Gem so you can install it with:

    sudo gem install rack-backend-api

HOW TO USE IT
=============

BackendAPI is a Rack middleware that you have to put before your actual backend/CMS, 
and generaly after an authentication middleware.
And it takes care of everything involving interraction with your database.

A rackup stack for your application might look like this:

    map '/' do
		  run Frontend
		end
		
		map '/admin' do
		  use Rack::Auth::Basic, "your-realm" do |username, password|
			  [username, password] == ['username', 'password']
			end
		  use BackendAPI
		  run Backend
		end

Your backend receives every request that the Restful API doesn't recognize.
The BackendAPI recognize requests following this scheme:

    METHOD /path-to-the-middleware/model_class/ID

The ID is not always relevant.
So if you have a model class called BlogPost and you want to get the form for the entry with ID 4:

    GET /admin/blog_post/4

If you don't put an ID, it means you want the form for a brand new entry:

    GET /admin/blog_post



When you use the BackendAPI, your CMS is just about nice tricks,
nice interface using Ajax and getting the best of what the API has to offer.



REST API
--------

Use Rack::MethodOverride if you don't have access to HTTP methods like PUT or DELETE

ORM
---

Adapter is loaded automatically if known and required before Backend

How to plug an ORM to ::Rack::Backend ?
---------------------------------------

Model::backend_single( id ) Should return a single database entry with the id provided