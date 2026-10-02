class User < ApplicationRecord
  has_secure_password

  has_many :properties, foreign_key: :host_id, inverse_of: :host, dependent: :restrict_with_error

  enum :role, { member: "member", moderator: "moderator" }, default: :member
  enum :status, { active: "active", suspended: "suspended" }, default: :active

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
end
