class User < ApplicationRecord
  has_secure_password

  has_many :properties, foreign_key: :host_id, inverse_of: :host, dependent: :restrict_with_error
  has_many :applications, foreign_key: :seeker_id, inverse_of: :seeker, dependent: :destroy
  has_many :reviews, foreign_key: :author_id, inverse_of: :author, dependent: :destroy
  has_many :saved_listings, dependent: :destroy
  has_many :saved, through: :saved_listings, source: :listing
  has_many :reports_filed, class_name: "Report", foreign_key: :reporter_id, inverse_of: :reporter, dependent: :destroy
  has_many :moderation_actions, foreign_key: :moderator_id, inverse_of: :moderator, dependent: :restrict_with_error
  has_many :moderation_actions_received, class_name: "ModerationAction", foreign_key: :target_user_id,
                                         inverse_of: :target_user, dependent: :nullify

  enum :role, { member: "member", moderator: "moderator" }, default: :member
  enum :status, { active: "active", suspended: "suspended" }, default: :active

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true,
                            uniqueness: { case_sensitive: false },
                            format: { with: URI::MailTo::EMAIL_REGEXP }
end
