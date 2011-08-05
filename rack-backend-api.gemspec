Gem::Specification.new do |s| 
  s.name = 'rack-backend-api'
  s.version = "0.2.1"
  s.platform = Gem::Platform::RUBY
  s.summary = "A Rack middleware that provides a simple API for your Admin section"
  s.description = "The purpose of this Rack Middleware is to provide an API that interfaces with database actions in order to build a CMS."
  s.files = `git ls-files`.split("\n").sort
  s.require_path = './lib'
  s.author = "Mickael Riga"
  s.email = "mig@mypeplum.com"
  s.homepage = "http://github.com/mig-hub/backend-api"
end