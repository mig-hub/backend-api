require 'rubygems'
require 'bacon'
require 'rack'
require 'fileutils' # fix Rack missing

Bacon.summary_on_exit

# Helpers
F = ::File
D = ::Dir
ROOT = F.dirname(__FILE__)+'/..'
def req_lint(app)
  ::Rack::MockRequest.new(::Rack::Lint.new(app))
end
dummy_app = proc{|env|[200,{'Content-Type'=>'text/plain'},['dummy']]}

$:.unshift ROOT+'/lib'
require ROOT+'/test/db.rb'
require 'backend_api'

def wrap(title, form) #mock wrapped versions of forms when not XHR
  BackendAPI::WRAP % [title,form]
end

class WrappingMiddleware # Wrap but with the previous middleware
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

describe 'API Misc' do
  
  should "Send 404 X-cascade if no response at the bottom of the Rack stack - Builder::run" do
    res = req_lint(BackendAPI.new).get('/zzz')
    res.status.should==404
    res.headers['X-Cascade'].should=='pass'
  end
  
  should 'Follow the Rack stack if response is not found - Builder::use' do
    res = req_lint(BackendAPI.new(dummy_app)).get('/')
    res.status.should==200
    res.body.should=='dummy'
  end
  
  should "Have a special path for sending version" do
    res = req_lint(BackendAPI.new(dummy_app)).get('/_version')
    res.status.should==200
    res.body.should==BackendAPI::VERSION.join('.')
  end
  
  should "Accept CamelCased or under_scrored class names" do
    # I prefer CamelCased as it only needs to be eval(ed)  
    # But people are used to under_scrored  
    # And also Windows servers are case insensitive
    res1 = req_lint(BackendAPI.new).get('/CamelCasedClass')
    res1.status.should==200
    res2 = req_lint(BackendAPI.new).get('/camel_cased_class')
    res2.status.should==200
    res1.body.should==res2.body.gsub('camel_cased_class', 'CamelCasedClass')
  end
end

describe 'API Post' do
  
  should "Create a new entry in the database and send a 201 response" do
    res = req_lint(BackendAPI.new).post('/haiku', :params => {'model' => {'title' => 'Summer', 'body' => "Summer was missing\nI cannot accept that\nI need to bake in the sun"}})
    res.status.should==201 # Created
    haiku = Haiku.order(:id).last
    haiku.title.should=='Summer'
    haiku.body.should=="Summer was missing\nI cannot accept that\nI need to bake in the sun"
  end
  
  should "Fallback to an update if there is an id provided" do
    req_lint(BackendAPI.new).post('/haiku/4', :params => {'model' => {'title' => 'Summer is not new !!!'}})
    Haiku.filter(:title => 'Summer is not new !!!').first.id.should==4
  end
  
  should "Accept a new entry with no attributes as long as it is valid" do
    res = req_lint(BackendAPI.new).post('/haiku')
    res.status.should==201
  end
  
  should "Send back the appropriate form when the creation is not valid" do
    
    res = req_lint(BackendAPI.new).post('/haiku', :params => {'model' => {'title' => '13'}})
    res.status.should==400
    compared = Haiku.new.set('title' => '13')
    compared.valid?
    res.body.should==wrap('Haiku', compared.backend_form('/haiku', ['title']))
    
    # Not wrapped when XHR
    res = req_lint(BackendAPI.new).post('/haiku', "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest", :params => {'model' => {'title' => '13'}})
    res.status.should==400
    res.body.should==compared.backend_form('/haiku', ['title'])
  end
  
  should "Use fields instead of model keys when validation fails (if possible)" do
    # That helps keeping the same order when validation doesn't pass
    # Also it keeps fields not sent when untouched, like checkboxes or images
    res = req_lint(BackendAPI.new).post('/haiku', :params => {'model' => {'title' => '13'}})
    res.body.should.not.match(/value='body'/)
    res = req_lint(BackendAPI.new).post('/haiku', :params => {'model' => {'title' => '13'}, 'fields' => ['title', 'body']})
    res.body.should.match(/value='body'/)
  end
  
  should "Accept a destination for when Entry is validated and request is not XHR" do
    res = req_lint(BackendAPI.new(dummy_app)).post('/haiku', :params => {'_destination' => 'http://www.domain.com/list.xml', 'model' => {'title' => 'Destination Summer'}})
    res.status.should==302
    res.headers['Location']=='http://www.domain.com/list.xml'
    Haiku.order(:id).last.title.should=='Destination Summer'
  end
  
  should "Keep _destination until form is validated" do
    req_lint(BackendAPI.new).post('/haiku', :params => {'_destination' => '/', 'model' => {'title' => '13'}}).body.should.match(/name='_destination'.*value='\/'/)
  end
  
  should "Keep _no_wrap until form is validated" do
    compared = Haiku.new.set('title' => '13')
    compared.valid?
    res = req_lint(WrappingMiddleware.new(BackendAPI.new)).post('/haiku', :params => {'_no_wrap' => 'true', 'model' => {'title' => '13'}})
    res.body.should==('<!-- '+compared.backend_form('/haiku',['title'], {:no_wrap=>'true'})+' -->')
    res.body.should.match(/name='_no_wrap'.*value='true'/)
  end
end

describe 'API Get' do
  
  should "Return the form for a fresh entry when no id is provided" do
    req_lint(BackendAPI.new).get('/haiku').body.should==wrap('Haiku', Haiku.new.backend_form('/haiku'))
  end
  
  should "Return the form for an update when id is provided" do
    req_lint(BackendAPI.new).get('/haiku/3').body.should==wrap('Haiku', Haiku[3].backend_form('/haiku/3'))
  end
  
  should "Be able to send a form with selected set of fields" do
    req_lint(BackendAPI.new).get('/haiku', :params => {'fields' => ['title']}).body.should==wrap('Haiku', Haiku.new.backend_form('/haiku', ['title']))
    req_lint(BackendAPI.new).get('/haiku/3', :params => {'fields' => ['title']}).body.should==wrap('Haiku', Haiku[3].backend_form('/haiku/3', ['title']))
  end
  
  should "Update the entry before building the form if model parameter is used" do
    update = {'title' => 'Changed'}
    req_lint(BackendAPI.new).get('/haiku', :params => {'model' => update}).body.should==wrap('Haiku', Haiku.new.set(update).backend_form('/haiku'))
    req_lint(BackendAPI.new).get('/haiku/3', :params => {'model' => update}).body.should==wrap('Haiku', Haiku[3].set(update).backend_form('/haiku/3'))
  end
  
  should "Return a partial if the request is XHR or param _no_wrap is used" do
    req_lint(BackendAPI.new).get('/haiku', "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest").body.should==Haiku.new.backend_form('/haiku')
    req_lint(BackendAPI.new).get('/haiku?_no_wrap=true').body.should==Haiku.new.backend_form('/haiku', nil, {:no_wrap=>'true'})
    req_lint(WrappingMiddleware.new(BackendAPI.new)).get('/haiku?_no_wrap=true').body.should==('<!-- '+Haiku.new.backend_form('/haiku', nil, {:no_wrap=>'true'})+' -->')
  end
end

describe 'API Put' do
  
  should "Update a database entry that exists and send a 201 response" do
    res = req_lint(BackendAPI.new).put('/haiku/3', :params => {'model' => {'body' => "Maybe I have no inspiration\nBut at least\nIt should be on three lines"}})
    res.status.should==201 # Created
    haiku = Haiku[3]
    haiku.body.should=="Maybe I have no inspiration\nBut at least\nIt should be on three lines"
    haiku.title.should=='Spring'
  end
  
  should "Work with MethodOverride" do
    req_lint(BackendAPI.new).post('/haiku/3', :params => {'_method' => 'PUT', 'model' => {'title' => 'Spring Wow !!!'}})
    Haiku[3].title.should=='Spring Wow !!!'
  end
  
  should "Not break if one updates with no changes" do
    res = req_lint(BackendAPI.new).put('/haiku/3')
    res.status.should==201
  end
  
  should "Send back the appropriate form when the creation is not valid" do
    
    res = req_lint(BackendAPI.new).put('/haiku/3', :params => {'model' => {'title' => '13'}})
    res.status.should==400
    compared = Haiku[3].set('title' => '13')
    compared.valid?
    res.body.should==wrap('Haiku', compared.backend_form('/haiku/3', ['title']))
    
    # Not wrapped when XHR
    res = req_lint(BackendAPI.new).put('/haiku/3', "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest", :params => {'model' => {'title' => '13'}})
    res.status.should==400
    res.body.should==compared.backend_form('/haiku/3', ['title'])
  end
  
  should "Use fields instead of model keys when validation fails (if possible)" do
    # That helps keeping the same order when validation doesn't pass
    # Also it keeps fields not sent when untouched, like checkboxes or images
    res = req_lint(BackendAPI.new).put('/haiku/3', :params => {'model' => {'title' => '13'}})
    res.body.should.not.match(/value='body'/)
    res = req_lint(BackendAPI.new).put('/haiku/3', :params => {'model' => {'title' => '13'}, 'fields' => ['title', 'body']})
    res.body.should.match(/value='body'/)
  end
  
  should "Accept a destination for when Update is validated and request is not XHR" do
    res = req_lint(BackendAPI.new(dummy_app)).post('/haiku/3', :params => {'_method' => 'PUT', '_destination' => '/', 'model' => {'title' => 'Spring destination !!!'}})
    res.status.should==302
    res.headers['Location']=='/'
    Haiku[3].title.should=='Spring destination !!!'
  end
  
  should "keep destination until form is validated" do
    req_lint(BackendAPI.new).put('/haiku/3', :params => {'_destination' => '/', 'model' => {'title' => '13'}}).body.should.match(/name='_destination'.*value='\/'/)
  end
  
  should "Keep _no_wrap until form is validated" do
    compared = Haiku[3].set('title' => '13')
    compared.valid?
    res = req_lint(WrappingMiddleware.new(BackendAPI.new)).post('/haiku/3', :params => {'_no_wrap' => 'true', 'model' => {'title' => '13'}})
    res.body.should==('<!-- '+compared.backend_form('/haiku/3',['title'], {:no_wrap=>'true'})+' -->')
    res.body.should.match(/name='_no_wrap'.*value='true'/)
  end
  
  should "Consider that a PUT request without an ID is a bulk update of position field (re-order)" do
    req_lint(BackendAPI.new).put('/TopFive', :params => {'TopFive'=>['2','3','1','5','4']})
    TopFive.order(:position).map(:flavour).should==['Vanilla','Chocolate','Strawberry','Apricot','Coconut']
  end
end

describe 'API Delete' do
  
  should "Delete a database entry that exists and send a 204 response" do
    res = req_lint(BackendAPI.new).delete('/haiku/1')
    res.status.should==204 # No Content
    Haiku[1].should==nil
  end
  
  should "Work with MethodOverride" do
    req_lint(BackendAPI.new(dummy_app)).post('/haiku/2', :params => {'_method' => 'DELETE'})
    Haiku[2].should==nil
  end
  
  should "Accept a destination" do
    res = req_lint(BackendAPI.new).delete('/haiku/3', :params => {'_destination' => '/'})
    res.status.should==302
    res.headers['Location']=='/'
    Haiku[3].should==nil
  end
end