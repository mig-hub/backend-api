::Sequel::Model.class_eval do
  class << self
    alias backend_get []
    alias backend_post new
  end
  alias backend_delete destroy
  alias backend_put set
  def backend_save?
    valid? && save
  end
  
  def backend_form(url, cols=nil, opts={})
    cols ||= default_backend_columns
    o = "<form action='#{url}' method='POST'>\n"
    o << (respond_to?(:crushyform) ? crushyform(cols) : backend_fields(cols))
    method = self.new? ? 'POST' : 'PUT'
    o << "<input type='hidden' name='_method' value='#{method}' />\n"
    o << "<input type='hidden' name='_destination' value='#{opts[:destination]}' />\n" unless opts[:destination].nil?
    o << "<input type='submit' name='save' value='SAVE' />\n"
    o << "</form>\n"
    o
  end
  
  # Silly but usable form prototype
  # Not really meant to be used in a real case
  # It uses a textarea for everything
  # Override it
  # Or even better, use Sequel-Crushyform plugin instead
  # It is shipped with Rack-Backend-API
  def backend_fields(cols)
    o = ''
    cols.each do |c|
      identifier = "#{id.to_i}-#{self.class}-#{c}"
      o << "<label for='#{identifier}'>#{c.to_s.capitalize}</label><br />\n"
      o << "<textarea id='#{identifier}' name='model[#{c}]'>#{self.send(c)}</textarea><br />\n"
    end
  end
  
  # Can be overridden
  def default_backend_columns
    columns - [:id]
  end
end