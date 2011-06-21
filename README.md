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

    METHOD /Backend-path/model_class/ID

The ID is not always relevant.
So if you have a model class called BlogPost and you want to get the form for the entry with ID 4:

    GET /admin/blog_post/4

If you don't put an ID, it means you want the form for a brand new entry:

    GET /admin/blog_post

Then if you need to delete the entry with ID 4:

    DELETE /admin/blog_post/4

To be honest, that is almost everything you need because the ORM adapter builds the forms 
and therefore use the right action and method for POST and PUT requests.

The problem sometimes with a Restful API is that in real life,
in spite of the fact that not every requests are GET or POST it is sometimes forced.
The href of a link is always a GET, and the method for a form is
overriden if it is not GET or POST.

This is why Rack has a very handy middleware called MethodOverride.
You don't have to `use` it because BackendAPI puts it on the stack for you.
Basically when you have it, you can send the method you really wanted in the POSTed parameter called "_method",
and the middleware override the method for you.
This is how the adapter makes forms with PUT requests.

But unfortunately you can only use MethodOverride on POST requests,
but you might want to have it on links.

Here is a concrete example:  
You want to put in your CMS a link for deleting blog post.
But a link is going to be a GET request.
Of course you could use Ajax and anyway you probably will,
but it is a good practice to make it possible without javascript.
So your link could look like this:

    <a href="/admin/blog_post/4?_method=DELETE"> X </a>

But it doesn't work because links are GET requests.
Fortunately this is a common task so there is a method that makes DELETE buttons available as a form:

    @blog_post.backend_delete_form("/admin/blog_post/4", { :destination => "/admin/list/blog_post" })

The `:destination` is where you go when the job is done.
You also can change the option `:submit_text` which is what the button says.
By default, the DELETE form button says "X".

The `:destination` option is also in the API as `_destination`.
Use it in order to specify where to go when the entry is validated.
Because before it is validated you'll get the form again with error messages.

Say we need a link for creating a blog post, and then when validated, we want to go back to the list page:

    <a href="/admin/blog_post?_destination=%2Fadmin%2Flist%2Fblog_post"> Create new Blog Post </a>

Of course, the page `/admin/list/blog_post` is a page of your Backend/CMS.
The form will be POSTed because there is no ID, which means it is a new entry.
On that list page, you could have a list of your posts with an "Edit" link:

    My Interesting Post Number 4 - <a href="/admin/blog_post/4?_destination=%2Fadmin%2Flist%2Fblog_post"> Edit </a>

You also have another option called `fields` which allows you to say which fields you want in that form.
The purpose of that is mainly to be able to edit a single value at a time:

    Title: My Super Blog - <a href="/admin/blog_post/4?fields[]=title&_destination=%2Fadmin%2Flist%2Fblog_post"> Edit </a>

This will make a link to a form for editing the title of that Blog Post.
Please note that the option `fields` is an array.

Also don't forget to escape the URI like in the examples above.
You can do that with Rack::Utils :

    ::Rack::Utils.escape "/admin/list/blog_post"

The option `:submit_text` is also available through the API as `_submit_text`.
It says "SAVE" by default but you might want it to say "CREATE" and "UPDATE" in appropriate cases,
like we did in the example.

A LITTLE BIT OF JAVASCRIPT
==========================

This is a very crude way of dealing with forms I have to say.
And it is only like that for having unobtrusive javascript.
When you use the BackendAPI, your CMS is just about nice tricks,
nice interface using Ajax and getting the best of what the API has to offer.

The forms are really meant to be requested via an XHR,
so that you have access to style and javascript widgets like a date-picker for example.

HOW TO PLUG AN ORM
==================

For the moment the only adapter available is for the Sequel ORM,
but it should be fairly easy to create one for any other ORM.
If you do one for DataMapper or whatever, please consider contributing
because it would make BackendAPI more interesting.

The adapter for Sequel is a regular plugin, but you don't have to declare it.
It is done automatically if the constant `Sequel` is defined.

Here are the methods to implement, most of them are just aliases for having a single name:

- `Model::backend_get( id )` Should return a single database entry with the id provided
- `Model::backend_post( hash-of-values )` Generaly equivalent to Model::new, it creates a new entry with provided values and without validating or saving
- `Model#backend_delete` Instance method that destroys the entry
- `Model#backend_put( hash-of-values )` Generaly equivalent to Model::update, it updates an existing entry with provided values and without validating or saving

Others are slightly more sophisticated:

- `Model#backend_save?` Returns true if the entry is validated and saved. It generally triggers the error messages for the form as well.
- `Model#default_backend_columns` This the list of columns in the forms when the list of fields is not provided via `fields` option
- `Model#backend_form( action_url, columns=nil, options={} )` It is only the wrapping of the form without the actual fields. Try to implement it like the Sequel one.
- `Model#backend_fields( columns )` These are the actual fields. There is a default behavior that basically puts a textarea for everything. That works in most cases but this is meant to be overriden for a better solution. We recommand [Crushyform](https://rubygems.org/gems/sequel-crushyform) for Sequel because we did it so we know it plays well with BackendAPI, and also because you don't have anything more to do. BackendAPI knows you have [Crushyform](https://rubygems.org/gems/sequel-crushyform) and use it to create the fields.