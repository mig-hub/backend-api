class BackendAPI
  VERSION = [0,3,2]
  WRAP = <<-EOT
  <!doctype html>
  <html>
  <head><meta charset="UTF-8" /><title>%s</title></head>
  <body>
  %s
  </body>
  </html>
  EOT
  
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
    form = @model_instance.backend_form(@req.path, @req['fields'], :destination => @req['_destination'], :submit_text => @req['_submit_text'], :no_wrap => @req['_no_wrap'])
    @res.write(wrap_response(form))
  end
  
  # Update
  def put
    if @id.nil? && @req[@model_class_name]
      @model_class.sort(@req[@model_class_name])
    else
      @model_instance.backend_put @req['model']
      save_and_respond
    end
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
      @model_class = Kernel.const_get(@model_class_name)
      @model_instance = @model_class.backend_get(@id) unless @id.nil?
      @clone_instance = @model_class.backend_get(@req['clone_id']) unless @req['clone_id'].nil?
      unless @clone_instance.nil?
        @req['fields'] ||= @clone_instance.cloning_backend_columns.map{|k|k.to_s}
        @req['model'] = @clone_instance.backend_values.select{|k,v| @req['fields'].include?(k.to_s)}
      end
      @req['model'] ||= {}
      send_404 if @model_instance.nil?&&!@id.nil?
    else
      send_404
    end
  end
  
  def send_404
    @res.status=404 # Not Found
    @res.headers['X-Cascade']='pass'
    @res.write 'Not Found'
  end
  
  def camel_case(s)
    return if s.nil?
    c = RUBY_VERSION>='1.9.0' ? s[0].ord : s[0]
    c>=65&&c<=90 ? s : s.split('_').map{|e|e.capitalize}.join
  end
  
  def save_and_respond
    if @model_instance.backend_save?
      if @req['_destination'].nil?
        @res.write(wrap_response(@model_instance.backend_show))
        @res.status=201 # Created
      else
        @res.redirect(::Rack::Utils::unescape(@req['_destination']))
      end
    else
      form = @model_instance.backend_form(@req.path, @req['fields']||@req['model'].keys, :destination => @req['_destination'], :submit_text => @req['_submit_text'], :no_wrap => @req['_no_wrap'])
      @res.write(wrap_response(form))
      @res.status=400 # Bad Request
    end
  end
  
  def wrap_response(content)
    if @req['_no_wrap'] || @req.xhr?
      content
    else
      WRAP % [@model_class_name, content]
    end
  end
  
end

# Require Adapter when known ORM detected
::Sequel::Model.plugin :rack_backend_api_adapter if defined? Sequel
