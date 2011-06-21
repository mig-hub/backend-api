class BackendAPI
  VERSION = [0,0,0]
  
  # Automatically use MethodOverride before
  # Thx Konstantin Haase for the trick
  def self.new(*); ::Rack::MethodOverride.new(super); end 
  def initialize(app=nil); @app = app; end
  def call(env); dup.call!(env); end
  
  def call!(env)
    @req = ::Rack::Request.new(env)
    @res = ::Rack::Response.new
    
    # Simple dispatcher
    @model_name, @id, *a = @req.path_info.split('/').find_all{|s| s!=''}
    
    # Special case
    return @res.finish{@res.write(v)} if @model_name=='_version'
    
    build_model_vars
    __send__(@req.request_method.downcase) unless @res.status==404
    
    @res.status==404&&!@app.nil? ? @app.call(env) : @res.finish
  end
  
  private
  
  # =========
  # = Paths =
  # =========
  
  def v; VERSION.join('.'); end
  
  # Create
  def post
    return put unless @id.nil?
    @model_instance = @model_class.backend_post(@req['model'])
    save_and_respond
  end
  
  # Read
  def get
    @model_instance ||= @model_class.backend_post
    @model_instance.backend_put @req['model']
    @res.write @model_instance.backend_form(@req.path, @req['fields'], :destination => @req['_destination'], :submit_text => @req['_submit_text'] )
  end
  
  # Update
  def put
    @model_instance.backend_put @req['model']
    save_and_respond
  end
  
  # Delete
  def delete
    @model_instance.backend_delete
    @req['_destination'].nil? ? @res.status=204 : @res.redirect(::Rack::Utils::unescape(@req['_destination'])) # 204 No Content
  end
  
  # Cost less than checking if is not GET, POST, PUT or DELETE
  def head; get; end; def options; get; end; def patch; get; end; def trace; get; end
  
  # ===========
  # = Helpers =
  # ===========
  
  def build_model_vars
    @model_class_name = camel_case(@model_name)
    if !@model_name.nil? && ::Object.const_defined?(@model_class_name)
      @model_class = eval(@model_class_name)
      @model_instance = @model_class.backend_get(@id.to_i) unless @id.nil?
      @req['model'] ||= {}
    else
      @res.status=404 # Not Found
      @res.headers['X-Cascade']='pass'
      @res.write 'Not Found'
    end
  end
  
  def camel_case(s)
    s.to_s.split('_').map{|e|e.capitalize}.join
  end
  
  def save_and_respond
    if @model_instance.backend_save?
      if @req['_destination'].nil?
        @res.write 'OK'
        @res.status=201 # Created
      else
        @res.redirect(::Rack::Utils::unescape(@req['_destination']))
      end
    else
      @res.write @model_instance.backend_form(@req.path, @req['model'].keys, :destination => @req['_destination'], :submit_text => @req['_submit_text'])
      @res.status=400 # Bad Request
    end
  end
  
end

# Require Adapter when known ORM detected
::Sequel::Model.plugin :rack_backend_api_adapter if defined? Sequel