class User < ApplicationRecord
  FIELD_LIMIT = 254
  STATUSES = %w[active blocked].freeze
  has_secure_password
  has_many :sessions, dependent: :delete_all
  normalizes :email, with: ->(email) { email.strip.downcase }
  normalizes :full_name, :job_position, with: lambda(&:strip)
  validates :full_name, :email, presence: true, length: { maximum: FIELD_LIMIT }
  validates :job_position, length: { maximum: FIELD_LIMIT }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES }
  scope :recent, -> { order(Arel.sql('last_login_at DESC NULLS LAST'), id: :desc) }
  def active?
    status == 'active'
  end
end
