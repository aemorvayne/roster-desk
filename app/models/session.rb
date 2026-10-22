class Session < ApplicationRecord
  belongs_to :user
  def self.start(user)
    transaction do
      user.update!(last_login_at: Time.current)
      create!(user: user)
    end
  end
end
