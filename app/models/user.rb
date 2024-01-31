class User < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable,
         :validatable, :omniauthable, :registerable

  has_many :mindmaps, dependent: :destroy
  has_many :mindmap_users, dependent: :destroy
  has_many :shared_mindmaps, through: :mindmap_users

  validates :first_name, :last_name, presence: true
  enum role: { user: 0, superadmin: 1 }
  enum status: { inactive: 0, active: 1 }

  def self.ransackable_associations(auth_object = nil)
    ["mindmap_users", "mindmaps", "shared_mindmaps"]
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "current_sign_in_at", "current_sign_in_ip", "email", "encrypted_password", "first_name", "id", "last_name", "last_sign_in_at", "last_sign_in_ip", "login", "provider", "remember_created_at", "reset_password_sent_at", "reset_password_token", "role", "sign_in_count", "status", "uid", "updated_at"]
  end

  def self.from_omniauth(auth)
    if where(email: auth.info.email || "#{auth.uid}@#{auth.provider}.com").present?
      where(email: auth.info.email || "#{auth.uid}@#{auth.provider}.com").first do |user|
        user.provider = auth.provider
        user.uid = auth.uid
        user.first_name = auth.info.first_name rescue nil
        user.last_name = auth.info.last_name rescue nil
        user.email = auth.info.email || "#{auth.uid}@#{auth.provider}.com"
        user.login = auth.info.email || "#{auth.uid}@#{auth.provider}.com"
        user.first_name ||= user.login
        user.last_name ||= user.login
        user.password = Devise.friendly_token[0, 20]
      end
    else
      nil
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def active_for_authentication?
    super and self.active?
  end

  def inactive_message
    "You are not allowed to log in!"
  end

  def admin?
    superadmin?
  end
end
