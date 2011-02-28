=begin

            ________         ____                             
           /_  __/ /_  ___  / __ )__  __________  ____ ___  __
            / / / __ \/ _ \/ __  / / / / ___/ _ \/ __ `/ / / /
           / / / / / /  __/ /_/ / /_/ / /  /  __/ /_/ / /_/ / 
          /_/ /_/ /_/\___/_____/\__,_/_/   \___/\__,_/\__,_/

=end

require 'sinatra/base'

module Sinatra
  module TheBureau
    
    module Helpers
    end
    
    def self.registered(app)
      app.helpers TheBureau::Helpers
    end
    
  end
  register TheBureau
end