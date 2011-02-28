Gem::Specification.new do |s| 
  s.name = 'the-bureau'
  s.version = "0.0.1"
  s.platform = Gem::Platform::RUBY
  s.summary = "Painless CMS for the Sinatra web framework"
  s.description = "Easily create a relational CMS using the Sinatra web framework"
  s.files = `git ls-files`.split("\n").sort
  s.require_path = '.'
  s.author = "Mickael Riga"
  s.email = "mig@mypeplum.com"
  s.homepage = "http://github.com/mig-hub/the-bureau"
end