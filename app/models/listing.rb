class Listing < ApplicationRecord
  belongs_to :property
  has_one :neighborhood, through: :property
  has_many :applications, dependent: :destroy
  has_many :seekers, through: :applications
  has_many :reviews, through: :property
  has_many :saved_listings, dependent: :destroy
  has_many :savers, through: :saved_listings, source: :user
  has_many :reports, dependent: :destroy
  has_many :moderation_actions, foreign_key: :target_listing_id, inverse_of: :target_listing, dependent: :nullify

  # Rich text (bold, italics, lists, links) stored by Action Text in action_text_rich_texts.
  has_rich_text :description
  has_rich_text :house_rules

  # Photographs of the room, uploaded from the listing form. Cards use the small :card variant so
  # they never download the full-resolution file; the listing page uses :large.
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTO_SIZE = 5.megabytes
  MAX_PHOTOS = 10

  has_many_attached :photos do |attachable|
    attachable.variant :card, resize_to_fill: [ 600, 400 ]
    attachable.variant :large, resize_to_limit: [ 1600, 1200 ]
  end

  enum :status, {
    draft: "draft",
    published: "published",
    reserved: "reserved",
    rented: "rented",
    withdrawn: "withdrawn"
  }, default: :draft

  validates :title, presence: true
  validates :monthly_rent, numericality: { only_integer: true, greater_than: 0 }
  validates :deposit, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :minimum_stay_months, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :available_from, presence: true
  # Only on create, so historical listings (e.g. already rented) stay valid when edited later.
  validate :available_from_not_in_past, on: :create
  validate :photos_are_images_within_size_limit

  # Only drafts are deleted. A listing that was published may have applications, so it is withdrawn
  # instead and the seekers keep their history (and the visits and reviews that hang from it).
  before_destroy :ensure_draft, prepend: true

  # Filter scopes are chainable and return everything when the argument is blank,
  # because they are fed straight from form params (which arrive as strings).

  # Rooms that are available on or before the given date, i.e. `available_from <= date`.
  scope :available_by, ->(date) { date.present? ? where(available_from: ..date) : all }
  scope :under_rent, ->(amount) { amount.present? ? where(monthly_rent: ..amount.to_i) : all }
  scope :in_neighborhood, ->(id) { id.present? ? joins(:property).where(properties: { neighborhood_id: id }) : all }
  scope :furnished_only, -> { where(furnished: true) }
  scope :with_private_bathroom, -> { where(private_bathroom: true) }
  scope :cheapest_first, -> { order(:monthly_rent) }
  scope :soonest_available, -> { order(:available_from) }

  def host
    property.host
  end

  def visible_to?(user)
    !draft? || (user.present? && host == user)
  end

  # Lifecycle: draft -> published -> reserved (accepting an applicant) -> rented, or withdrawn while
  # it is published or reserved. Each transition raises ActiveRecord::RecordInvalid, with the
  # reason in `errors`, when the listing is not in a state that allows it.
  def publishable?
    draft?
  end

  def withdrawable?
    published? || reserved?
  end

  def rentable?
    reserved?
  end

  def publish!
    transition_to!(:published, allowed: publishable?, otherwise: "can only be published while it is a draft")
  end

  # Withdrawing also answers the applications still waiting for a decision: they are rejected,
  # together with the change of state or not at all.
  def withdraw!
    transaction do
      transition_to!(:withdrawn, allowed: withdrawable?, otherwise: "cannot be withdrawn once it is #{status}")
      applications.undecided.update_all(status: "rejected", updated_at: Time.current)
    end
  end

  # Once the accepted housemate has moved in.
  def mark_rented!
    transition_to!(:rented, allowed: rentable?, otherwise: "can only be marked as rented once an applicant is accepted")
  end

  private

  def transition_to!(new_status, allowed:, otherwise:)
    unless allowed
      errors.add(:status, otherwise)
      raise ActiveRecord::RecordInvalid, self
    end

    update!(status: new_status)
  end

  def ensure_draft
    return if draft?

    errors.add(:base, "Only a draft can be deleted. Withdraw the listing instead.")
    throw :abort
  end

  def available_from_not_in_past
    return if available_from.blank?

    errors.add(:available_from, "cannot be in the past") if available_from < Date.current
  end

  def photos_are_images_within_size_limit
    errors.add(:photos, "can be at most #{MAX_PHOTOS}") if photos.size > MAX_PHOTOS

    photos.each do |photo|
      unless photo.content_type.in?(PHOTO_CONTENT_TYPES)
        errors.add(:photos, "#{photo.filename} is not a JPEG, PNG or WebP image")
      end

      if photo.byte_size > MAX_PHOTO_SIZE
        errors.add(:photos, "#{photo.filename} is larger than #{MAX_PHOTO_SIZE / 1.megabyte} MB")
      end
    end
  end
end
