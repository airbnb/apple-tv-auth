class AuthToken
  attr_accessor :nonce, :short_code, :nonce_hash, :id

  MAX_SHORT_CODE_ATTEMPTS = 20

  REDIS_KEY_PREFIX = 'auth_token:'
  REDIS_EXPIRY = 5 * 60 # 5 minutes
  REDIS_HOST = '127.0.0.1'
  REDIS_PORT = 6379

  SHORT_CODE_LENGTH = 6
  SHORT_CODE_CHARACTERS = %w{A B C D E F H J K M N P Q R S T W X Y Z 2 3 4 5 8 9}

  def initialize(options=nil)
    self.short_code = options['short_code']
    self.nonce = options['nonce']
    self.nonce_hash = options['nonce_hash']
    self.id = options['id']
    @new_record = options['new_record']
  end

  def authorize(id)
    unless self.id
      self.id = id
      save
    end
  end

  def authenticate(nonce)
    self.id && BCrypt::Password.new(self.nonce_hash) == nonce
  end

  def new_record?
    !!@new_record
  end

  def nonce_hash
    @nonce_hash ||= BCrypt::Password.create(@nonce)
  end

  def redis_key
    self.class.redis_key(short_code)
  end

  def refresh_expiry!
    if !new_record?
      self.class.redis.setex(redis_key, REDIS_EXPIRY, self.to_redis)
    end
  end

  def save
    # Never overwrite an existing key if this is a new link code
    if new_record?
      if self.class.redis.setnx(redis_key, self.to_redis)
        @new_record = false
        self.class.redis.expire(redis_key, REDIS_EXPIRY)
      end
    else
      self.class.redis.setex(redis_key, REDIS_EXPIRY, self.to_redis)
    end
  end

  def to_json
    {
      short_code: @short_code,
      nonce: @nonce
    }.to_json
  end

  def to_redis
    {
      'short_code' => @short_code,
      'nonce_hash' => nonce_hash,
      'id' => id
    }.to_json
  end

  def self.create
    token = nil
    attempt = 0
    # There could be a collision with a previously generated short code so we
    # will try up to MAX_SHORT_CODE_ATTEMPTS times before giving up.
    loop do
      attempt += 1
      token = self.new(
        'short_code' => self.generate_short_code,
        'nonce' => self.generate_nonce,
        'new_record' => true
      )
      break if token.save
      if attempt > MAX_SHORT_CODE_ATTEMPTS
        raise "Unable to create new AuthToken"
      end
    end
    token
  end

  def self.get(short_code)
    self.new(JSON.parse(self.redis.get(redis_key(short_code.upcase))))
  end

  def self.generate_nonce
    SecureRandom.uuid
  end

  def self.generate_short_code
    # Generate a number with the right amount of entropy.
    SecureRandom.random_number(
      SHORT_CODE_CHARACTERS.length**SHORT_CODE_LENGTH
    # Convert it to the correct base based on our character set.
    ).to_s(SHORT_CODE_CHARACTERS.length).split('').map { |position|
      # Map each digit to a character in our set.
      SHORT_CODE_CHARACTERS[position.to_i(SHORT_CODE_CHARACTERS.length)]
    # Turn it back into a string and pad it if necessary.
    }.join('').rjust(SHORT_CODE_LENGTH, SHORT_CODE_CHARACTERS.first)
  end

  def self.redis
    @redis ||= Redis.new(host: REDIS_HOST, port: REDIS_PORT)
  end

  def self.redis_key(short_code)
    "#{REDIS_KEY_PREFIX}#{short_code}"
  end
end
