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
  # Silly but usable form prototype
  # Not really meant to be used in a real case
  # It does not manage multipart
  # Override it
  def backend_form(url, cols=nil, opts={})
    cols ||= columns - [:id]
    o = "<form action='#{url}' method='POST'>\n"
    cols.each do |c|
      identifier = "#{self.class}-#{id.to_i}-#{c}"
      o << "<label for='#{identifier}'>#{c.to_s.capitalize}</label><br />\n"
      o << "<textarea id='#{identifier}' name='model[#{c}]'>#{self.send(c)}</textarea><br />\n"
    end
    method = self.new? ? 'POST' : 'PUT'
    o << "<input type='hidden' name='_method' value='#{method}' />\n"
    o << "<input type='hidden' name='_destination' value='#{opts[:destination]}' />\n" unless opts[:destination].nil?
    o << "<input type='submit' name='save' value='SAVE' />\n"
    o << "</form>\n"
    o
  end
end