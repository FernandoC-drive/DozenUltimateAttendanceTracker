class RecsportsCredential < ApplicationRecord
  enum :access_mode, { shared_credentials: 0, manual_upload: 1, browser_assisted: 2 }, default: :shared_credentials

  before_validation :ensure_browser_sync_token

  validates :form_url, presence: true, if: -> { shared_credentials? || browser_assisted? }
  validates :browser_sync_token, presence: true, uniqueness: true

  private

  def ensure_browser_sync_token
    self.browser_sync_token ||= SecureRandom.hex(24)
  end
end
