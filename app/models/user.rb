class User < ApplicationRecord
  has_many :microposts, dependent: :destroy

  attr_accessor :remember_token, :activation_token, :reset_token

  before_save   :downcasce_email
  before_create :create_activation_digest

  VALID_EMAIL = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  validates :name,  presence: true, length: { maximum: 50 }
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL },
                    uniqueness: { case_sensitive: false }
  validates :password, presence: true, length: { minimum: 6 },
                       allow_nil: true
  has_secure_password

  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ?
              BCrypt::Engine::MIN_COST
            : BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end

  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # トークンのダイジェストをDBに保存する
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  def forget
    update_attribute(:remember_digest, nil)
  end
  
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def activate
    #update_attribute(:activated, true)
    #update_attribute(:activated_at, Time.zone.now)
    update_columns(activated: true, activated_at: Time.zone.now)
  end

  def send_activation_mail
    UserMailer.account_activation(self).deliver_now
  end

  def send_password_reset_mail
    UserMailer.password_reset(self).deliver_now
  end

  def create_reset_digest
    self.reset_token = User.new_token
    #update_attribute(:reset_digest, User.digest(reset_token))
    #update_attribute(:reset_sent_at, Time.zone.now)
    update_columns(reset_digest: User.digest(reset_token),
                   reset_sent_at: Time.zone.now)
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.where("user_id = ?", id)
  end

  private 
    
    def downcasce_email
      #self.email = email.downcase
      email.downcase!
    end

    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end

end
