class User < ApplicationRecord
  FIELD_LIMIT = 254
  STATUSES = %w[active blocked].freeze
  SORT_FIELDS = %w[full_name email status].freeze
  attr_reader :password
  validate :password_required
  has_many :sessions, dependent: :delete_all
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_position, with: lambda(&:strip)
  validates :full_name, :email, presence: true, length: { maximum: FIELD_LIMIT }
  validates :job_position, length: { maximum: FIELD_LIMIT }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  scope :recent, -> { order(Arel.sql('last_login_at DESC NULLS LAST'), id: :desc) }
  def self.directory_order(field)
    return recent unless SORT_FIELDS.include?(field)
    order(field => :asc, id: :asc)
  end

  def active?
    status == 'active'
  end

  def password=(value)
    @password = value.to_s
    self.password_digest = Argon2::Password.create(@password) unless @password.empty?
  end

  def authenticate_password(value)
    password_digest.present? && Argon2::Password.verify_password(value.to_s, password_digest) && self
  end
  alias authenticate authenticate_password

  def password_required
    errors.add(:password, "can't be empty") if password_digest.blank?
  end
end
