DataMapper.setup(:default, {:adapter  => "redis"})

require './models/auth_token.rb'
require './models/user.rb'

DataMapper.finalize
