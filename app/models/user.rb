class User < ApplicationRecord
  has_secure_password

  enum :role, { member: "member", moderator: "moderator" }, default: :member
  enum :status, { active: "active", suspended: "suspended" }, default: :active

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
end
