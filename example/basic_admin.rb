BASIC_ADMIN = proc{
  
  map '/' do
    run proc{|env|
      title = "<h1>Main Menu</h1>\n"
      menu = env['basic_admin.models'].map do |m|
        "<p><a href='%s/list/%s'>%s Management</a></p>\n" % [env['SCRIPT_NAME'],m,m]
      end.join
      [200,{'Content-Type'=>'text/html'},[title,menu]]
    }
  end
  map '/list' do
    run proc{|env|
      path = env['SCRIPT_NAME']+env['PATH_INFO']
      escaped_path = ::Rack::Utils::escape path
      root_path = env['SCRIPT_NAME'].slice(0,env['SCRIPT_NAME'].rindex('/'))
      model_name = env['PATH_INFO'][1..-1]
      api_model_path = "%s/%s" % [root_path,model_name]
      title = "<h1>%s List</h1>\n" % [model_name]
      create_link = "<p><a href='%s?_destination=%s'>Create %s</a></p>\n" % [api_model_path,escaped_path,model_name]
      list = eval(model_name).all.map do |m|
        api_inst_path = "%s/%s" % [api_model_path,m.id]
        link = "<a href='%s?_destination=%s'>%s %s</a>\n" % [api_inst_path,escaped_path,model_name,m.id]
        delete_form = <<-EOF
        <form action='%s' method='POST'>
        %s
        <input type='hidden' name='_method' value='DELETE' />
        <input type='hidden' name='_destination' value='%s' />
        <input type='submit' name='delete' value='x' />
        </form>
        EOF
        delete_form = delete_form % [api_inst_path,link,escaped_path]
      end.join
      [200,{'Content-Type'=>'text/html'},[title,create_link,list]]
    }
  end
  
}