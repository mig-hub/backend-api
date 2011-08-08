BACKEND API
===========

The inspiration for this Rack middleware is the CouchDB API.
We wanted to create a middleware that provides every URLs you need in order to build a CMS
while only concentrating on the interface.
All the database interactions are handled by the API.

The project is made with a Rack middleware and a small adapter for the Sequel ORM.
One of the chapter explains how to create an adapter for another ORM (if you do one, please share).

Also this tool is part of a toolkit that is made for creating a CMS (in a modular way).
Here are the others:

- [Crushyform](https://github.com/mig-hub/sequel-crushyform): A Sequel plugin for building forms in a painless way and as flexible as possible.
- [Stash Magic](https://github.com/mig-hub/stash_magic): A simple attachment system that also handles thumbnails or other styles via ImageMagick. Originally tested on Sequel ORM but purposedly easy to plug to something else.
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
and generally after an authentication middleware.
And it takes care of everything involving interaction with your database.

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
      run Backend.new
    end

Your backend receives every request that the Restful API doesn't recognise.
The BackendAPI recognises requests following this scheme:

    METHOD /Backend-path/model_class/ID

The ID is not always relevant.
So if you have a model class called BlogPost and you want to get the form for the entry with ID 4:

    GET /admin/blog_post/4

If you don't put an ID, it means you want the form for a brand new entry:

    GET /admin/blog_post

Then if you need to delete the entry with ID 4:

    DELETE /admin/blog_post/4

The API also understands a CamelCased class name:

    DELETE /admin/BlogPost/4

This is my fave personally, but unfortunately it seems that windows servers are case insensitive.
Which means that if you have one, you need to stick with the under_scored names.

To be honest, that is almost everything you need because the ORM adapter builds the forms 
and therefore use the right action and method for POST and PUT requests.

The problem sometimes with a Restful API is that in real life,
in spite of the fact that not every requests are GET or POST it is sometimes forced.
The href of a link is always a GET, and the method for a form is
overridden if it is not GET or POST.

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

Another thing to note is that you don't have to use a destination for when something is created or updated.
If you do not use destination, the API will call the instance method `Model#backend_show` on the entry.
By default it just says `'OK'` but you can override the method in order to send whatever you want.
This comes handy when you use ajax and want a representation of the entry once it's created.

SORTING
=======

The way I implemented it for the moment might be a bit awkward, but I needed that option.
Basically when you use a PUT request without an ID, the API assumes that you want to sort the entries of the class.
For instance:

    PUT /admin/TopFive

Then it will look for the parameter that has the name of the class which should be a list of ids.
And it will update each entry with its position field set to the position in the array.
That is more or less what people are used to do when sorting via javascript.

    TopFive[]=4&TopFive[]=2&TopFive[]=1&TopFive[]=3

This is an example of a query string for the order: 4,2,1,3. But this is just an example, it has to be a PUT request
or a POST request with method override.

The position field is obviously known by the ORM.
For Sequel (which adapter is included) it assumes that you use the `:list` plugin.
It is shipped with Sequel.

Still a work in progress but it satisfies the tests so far.

A LITTLE BIT OF JAVASCRIPT
==========================

This is a very crude way of dealing with forms I have to say.
And it is only like that for having unobtrusive javascript.
When you use the BackendAPI, your CMS is just about nice tricks,
nice interface using Ajax and getting the best of what the API has to offer.

The forms are really meant to be requested via an XHR,
so that you have access to style and javascript widgets like a date-picker for example.

Nevertheless you might want to have a better unobtrusiveness for your javascript, meaning
you want to be able to wrap the forms yourself with your nice layout.
That is also valuable if you want to have no javascript at all.

This is exactly what the option `_no_wrap` is for. Basically if you want that,
it is better to have your Backend middleware before the API in the Rack stack:

    map '/' do
      run Frontend
    end

    map '/admin' do
      use Rack::Auth::Basic, "your-realm" do |username, password|
        [username, password] == ['username', 'password']
      end
      use Backend
      run BackendAPI.new
    end

Then what you do is that you make your Backend middleware aware that if the GET param
`_no_wrap` is used, it has to forward the request and then wrap the body:

    class Backend
      def initialize(app); @app = app; end
      def call(env)
        if Rack::Request.new(env)['_no_wrap']
          status, header, body = @app.call(env)
          res = Rack::Response.new('<!-- ', status, header)
          if body.respond_to? :to_str
            res.write body.to_str
          elsif body.respond_to?(:each)
            body.each { |part|
              res.write part.to_s
            }
          end
          res.write(' -->')
          res.finish
        else
          [200, {'Content-Type'=>'text/plain'}, ['not wrapped']]
        end
      end
    end

Here, if the param `_no_wrap` is used, this middleware will ask the response to the API middleware
and then will create a new Response with the body wrapped between `<!-- ` and ` -->`.

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
- `Model::backend_post( hash-of-values )` Generally equivalent to Model::new, it creates a new entry with provided values and without validating or saving
- `Model#backend_delete` Instance method that destroys the entry
- `Model#backend_put( hash-of-values )` Generally equivalent to Model::update, it updates an existing entry with provided values and without validating or saving

Others are slightly more sophisticated:

- `Model#backend_save?` Returns true if the entry is validated and saved. It generally triggers the error messages for the form as well.
- `Model#default_backend_columns` This the list of columns in the forms when the list of fields is not provided via `fields` option
- `Model#backend_form( action_url, columns=nil, options={} )` It is only the wrapping of the form without the actual fields. Try to implement it like the Sequel one.
- `Model#backend_fields( columns )` These are the actual fields. There is a default behaviour that basically puts a `textarea` for everything. That works in most cases but this is meant to be overridden for a better solution. We recommend [Crushyform](https://rubygems.org/gems/sequel-crushyform) for Sequel because we did it so we know it plays well with BackendAPI, and also because you don't have anything more to do. BackendAPI knows you have [Crushyform](https://rubygems.org/gems/sequel-crushyform) and use it to create the fields.
- `Model#backend_delete_form( action_url, options={})` Basically sugar for Model#backend_form but with an empty array for columns, and these options `{:submit_text=>'X', :method=>'DELETE'}` predefined which you can override. We've seen before that it is for creating DELETE forms.
- `Model#backend_show` What is sent when PUT or POST is successful and there is no `_destination`. Default is `'OK'`
- `Model::sort( array-of-ids )` It is used to do a bulk update of the position field, hence: re-order

CAN I HELP ?
============

Of course you can. This project is still in heavy development and it definitely lacks some error checking and stuff.
So do not hesitate to fork the project on Github and request a `pull`. If you don't use Github, you still can send a patch.
But that's less fun isn't it?

THANX
=====

I'd like to thank [Manveru](https://github.com/manveru), [Pistos](https://github.com/pistos) and many others on the #ramaze IRC channel for being friendly, helpful and obviously savvy.

Also I'd like to thank [Konstantin Haase](https://github.com/rkh) for the same reasons as he helped me many times on #rack issues,
and because [almost-sinatra](https://github.com/rkh/almost-sinatra) is just made with the 8 nicest lines of code to read.

CHANGE LOG
==========

0.0.1 First version
0.0.2 Accept CamelCased class names
0.0.3 Fix Form mockup
0.0.4 Partial available not only via XHR but also via `_no_wrap` param
0.0.5 Ordered list of fields to keep before validation
0.1.0 Introduce sorting functionality
0.2.0 Control what you send on 201 responses
0.2.1 Have a title in forms + Only use `_method` if not POST
0.2.2 Backend form should accept a block for populating the fields

COPYRIGHT
=========

(c) 2011 Mickael Riga - see file LICENSE for details