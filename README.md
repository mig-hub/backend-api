BACKEND API
===========

The inspiration for this Rack middleware is the CouchDB API.
We wanted to create a middleware that provides every URLs you need in order to build a CMS
while only concentrating on the interface.
All the database interactions are handled by the API.

The project is made with a Rack middleware and a small adapter for the Sequel ORM.
One of the chapter explains how to create an adpater for another ORM (if you do one, please share).

Also this tool is part of a toolkit that is made for creating a CMS (in a modular way).
Here are the others:

- [Crushyform](https://github.com/mig-hub/sequel-crushyform): A Sequel plugin for building forms in a painless way and as flexible as possible.
- [Stash Magic](https://github.com/mig-hub/stash_magic): A simple attachment system that also handles thumbnails or other styles via ImageMagick. Originaly tested on Sequel ORM but purposedly easy to plug to something else.
- [Cerberus](https://github.com/mig-hub/cerberus): A Rack middleware for form-based authentication.

This project is still at an early stage so don't hesitate to ask any question if the documentation lacks something.
And a good way to get started is to try the example in the example folder of this library.
It is a very basic (but complete) admin system.
A lot better if you have [Crushyform](https://rubygems.org/gems/sequel-crushyform) installed (nothing more to do except having it installed).

Once you are in the root directory of the library, you can start it with:

    rackup example/config.ru

The file `basic_admin.rb` contains the Backend itself and shows how to use the URLs of the API.

You can use it for any kind of Rack application (Sinatra, Ramaze, Merb, Rails...).
Ramaze/Innate is not the most obvious to use as a middleware, but this is the one I use the most,
so drop me a line if you don't know how to do.

HOW TO INSTALL
==============

This is a Gem so you can install it with:

    sudo gem install rack-backend-api

HOW TO USE IT
=============

BackendAPI is a Rack middleware that you have to put before your actual backend/CMS, 
and generaly after an authentication middleware.
And it takes care of everything involving interraction with your database.

In reality, it does not HAVE to be with the Backend but it makes sense and that way,
both share the authentication middleware.

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
The BackendAPI recognizes requests following this scheme:

    METHOD /Backend-path/model_class/ID

The ID is not always relevant.
So if you have a model class called BlogPost and you want to get the form for the entry with ID 4:

    GET /admin/blog_post/4

If you don't put an ID, it means you want the form for a brand new entry:

    GET /admin/blog_post

Then if you need to delete the entry with ID 4:

    DELETE /admin/blog_post/4

The API also understands a camelcased class name:

    DELETE /admin/BlogPost/4

This is my fave personally, but unfortunately it seems that windows servers are case insensitive.
Which means that if you have one, you need to stick with the under_scored names.

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
It is done automatically if the constant `Sequel` is defined (so you have to require Sequel first).

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
- `Model#backend_delete_form( action_url, options={})` Basically sugar for Model#backend_form but with an empty array for columns, and these options `{:submit_text=>'X', :method=>'DELETE'}` predefined which you can override. We've seen before that it is for creating DELETE forms.

THANX
=====

I'd like to thank [Manveru](https://github.com/manveru), [Pistos](https://github.com/pistos) and many others on the #ramaze IRC channel for being friendly, helpful and obviously savy.

Also I'd like to thank [Konstantin Haase](https://github.com/rkh) for the same reasons as he helped me many times on #rack issues,
and because [almost-sinatra](https://github.com/rkh/almost-sinatra) is just made with the 8 nicest lines of code to read.

CHANGE LOG
==========

0.0.1 First version
0.0.2 Accept CamelCased class names
0.0.3 Fix Form mockup

COPYRIGHT
=========

(c) 2011 Mickael Riga - see file LICENSE for details