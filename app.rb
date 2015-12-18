require 'bundler'
require 'json'
Bundler.require
require './models.rb'

Warden::Strategies.add(:password) do
  def valid?
    params['user_name'] && params['password']
  end

  def authenticate!
    user = User.get(params['user_name'])

    if user.nil?
      throw(:warden, message: "The user name you entered does not exist.")
    elsif user.authenticated?(params['password'])
      success!(user)
    else
      throw(:warden, message: "The user name and password combination ")
    end
  end
end

Warden::Strategies.add(:nonce) do
  def valid?
    params['short_code'] && params['nonce']
  end

  def authenticate!
    token = AuthToken.get(params['short_code'])
    user = User.get(token.user_name) if token
    token.refresh_expiry! unless user

    if token.nil? || user.nil?
      throw(:warden, message: "The code you entered has not been authorized.")
    elsif token.authenticated?(params['nonce'])
      # TODO: destroy token
      success!(user)
    else
      throw(:warden, message: "Invalid nonce provided.")
    end
  end
end

class AppleTvAuthExample < Sinatra::Base
  enable :sessions
  register Sinatra::Flash

  use Warden::Manager do |config|
    config.serialize_into_session { |user| user.user_name }
    config.serialize_from_session { |id| User.get(id) }
    config.scope_defaults :default,
      strategies: [ :password, :nonce ],
      action: 'auth/unauthenticated'
    config.failure_app = self
  end

  Warden::Manager.before_failure do |env,opts|
    env['REQUEST_METHOD'] = 'POST'
  end

  get '/authorize' do
    env['warden'].authenticate!
    erb :authorize
  end

  get '/' do
    binding.pry
    @token = AuthToken.create
    erb :token
  end

  post '/authorize' do
    env['warden'].authenticate!
    @current_user = env['warden'].user

    token = AuthToken.get(params['short_code'])
    if token
      token.authorize(@current_user.user_name)
      flash[:success] = "Successfully authorized #{token.short_code}"
      redirect '/authorize'
    else
      [403, 'Unauthorized']
    end
  end

  get '/auth/login' do
    erb :login
  end

  post '/auth/login' do
    env['warden'].authenticate!

    flash[:success] = "Successfully logged in"

    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end

  get '/auth/logout' do
    env['warden'].raw_session.inspect
    env['warden'].logout
    flash[:success] = 'Successfully logged out'
    redirect '/'
  end

  post '/auth/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?

    if params[:nonce]
      [403, env['warden.options'][:message] || "Unable to login via nonce"]
    else
      # Set the error and use a fallback if the message is not defined
      flash[:error] = env['warden.options'][:message] || "You must log in"
      redirect '/auth/login'
    end
  end

  get '/protected' do
    env['warden'].authenticate!

    erb :protected
  end
end
