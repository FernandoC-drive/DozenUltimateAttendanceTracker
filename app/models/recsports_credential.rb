class RecsportsCredential < ApplicationRecord
  enum :access_mode, { shared_credentials: 0, manual_upload: 1 }, default: :shared_credentials

  validates :form_url, presence: true, if: :shared_credentials?
end
