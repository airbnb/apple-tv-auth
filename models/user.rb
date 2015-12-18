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

# Create a test User
if User.count == 0
  user = User.create
  user.user_name = "admin"
  user.password = "admin"
  user.save
end
