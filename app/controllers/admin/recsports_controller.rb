module Admin
  class RecsportsController < BaseController
    def show
      @credential = RecsportsCredential.first_or_initialize(access_mode: :shared_credentials)
    end

    def update
      @credential = RecsportsCredential.first_or_initialize

      if @credential.update(credential_params)
        redirect_to admin_recsports_path, notice: "RecSports settings saved."
      else
        redirect_to admin_recsports_path, alert: @credential.errors.full_messages.to_sentence
      end
    end

    def test_access
      credential = RecsportsCredential.first
      raise "Missing RecSports configuration." unless credential

      if credential.manual_upload?
        credential.update!(last_checked_at: Time.current, last_error: nil, active: true)
        redirect_to admin_recsports_path, notice: "Manual upload mode is active."
        return
      end

      Recsports::Client.new(credential).test_access!
      credential.update!(last_checked_at: Time.current, last_error: nil, active: true)
      redirect_to admin_recsports_path, notice: "RecSports access test succeeded."
    rescue StandardError => e
      credential&.update(last_error: e.message, active: false)
      redirect_to admin_recsports_path, alert: "RecSports access failed or was revoked."
    end

    def sync_now
      credential = RecsportsCredential.first
      if credential.blank?
        redirect_to admin_recsports_path, alert: "Configure RecSports access first."
        return
      end

      RecsportsSyncJob.perform_later(manual_payload: params[:manual_payload])
      redirect_to admin_recsports_path, notice: "RecSports sync queued."
    end

    private

    def credential_params
      params.require(:recsports_credential).permit(:access_mode, :form_url, :username, :password, :active)
    end
  end
end
