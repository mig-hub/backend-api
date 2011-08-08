module ::Sequel::Plugins::RackBackendApiAdapter
  
  module ClassMethods
    def sort(list)
      list.each_with_index do |id, position|
        self[id].update(position_field=>position)
      end
    end
  end
  
  module InstanceMethods
    
    def self.included(model_class)
      model_class.class_eval do
        class << self
          alias backend_get []
          alias backend_post new
        end
        alias backend_delete destroy
        alias backend_put set
      end
    end
    
    def backend_save?; valid? && save; end
    
    def backend_form(url, cols=nil, opts={})
      cols ||= default_backend_columns
      if block_given?
        fields_list = ''
        yield(fields_list)
      else
        fields_list = respond_to?(:crushyform) ? crushyform(cols) : backend_fields(cols)
      end
      o = "<form action='#{url}' method='POST' #{"enctype='multipart/form-data'" if fields_list.match(/type='file'/)} class='backend-form'>\n"
      o << backend_form_title unless block_given?
      o << fields_list
      opts[:method] = 'PUT' if (opts[:method].nil? && !self.new?)
      o << "<input type='hidden' name='_method' value='#{opts[:method]}' />\n" unless opts[:method].nil?
      o << "<input type='hidden' name='_destination' value='#{opts[:destination]}' />\n" unless opts[:destination].nil?
      o << "<input type='hidden' name='_submit_text' value='#{opts[:submit_text]}' />\n" unless opts[:submit_text].nil?
      o << "<input type='hidden' name='_no_wrap' value='#{opts[:no_wrap]}' />\n" unless opts[:no_wrap].nil?
      cols.each do |c|
        o << "<input type='hidden' name='fields[]' value='#{c}' />\n"
      end
      o << "<input type='submit' name='save' value='#{opts[:submit_text] || 'SAVE'}' />\n"
      o << "</form>\n"
      o
    end
    
    def backend_delete_form(url, opts={}); backend_form(url, [], {:submit_text=>'X', :method=>'DELETE'}.update(opts)); end
    
    def backend_form_title
      n = self.respond_to?(:to_label) ? self.to_label : self.backend_to_label
      "<h2>#{'Edit ' unless self.new?}#{n}</h2>"
    end
    
    def backend_to_label; [self.new? ? 'New' : nil, model.name, id].compact!.join(' '); end

    # Silly but usable form prototype
    # Not really meant to be used in a real case
    # It uses a textarea for everything
    # Override it
    # Or even better, use Sequel-Crushyform plugin instead
    def backend_fields(cols)
      o = ''
      cols.each do |c|
        identifier = "#{id.to_i}-#{self.class}-#{c}"
        o << "<label for='#{identifier}'>#{c.to_s.capitalize}</label><br />\n"
        o << "<textarea id='#{identifier}' name='model[#{c}]'>#{self.send(c)}</textarea><br />\n"
      end
      o
    end

    # Can be overridden
    def default_backend_columns; columns - [:id]; end
    def backend_show; 'OK'; end
    
  end
  
end