class User
  include DataMapper::Resource
  include BCrypt

  property :user_name, String, :key => true
  property :password, BCryptHash

  def authenticated?(attempted_password)
    if self.password == attempted_password
      true
    else
      false
    end
  end
end
