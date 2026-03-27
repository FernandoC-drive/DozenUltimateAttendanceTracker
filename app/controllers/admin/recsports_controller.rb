module Admin
  class RecsportsController < BaseController
    skip_forgery_protection only: :browser_sync
    skip_before_action :require_login!, only: :browser_sync
    skip_before_action :require_coach!, only: :browser_sync
    before_action :set_browser_sync_headers, only: :browser_sync

    def show
      @credential = RecsportsCredential.first_or_initialize(access_mode: :shared_credentials)
      @credential.valid?
      @recent_events = RecsportsEvent.includes(participants: :user).recent_first.limit(10)
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

      if credential.browser_assisted?
        credential.update!(last_checked_at: Time.current, last_error: nil, active: true)
        redirect_to admin_recsports_path, notice: "Browser-assisted mode is active. Run the local sync script and complete Microsoft/Duo login in the opened browser."
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

      if credential.browser_assisted?
        redirect_to admin_recsports_path, alert: "Browser-assisted mode uses the local sync script instead of the in-app Sync now button."
        return
      end

      RecsportsSyncJob.perform_now(manual_payload: params[:manual_payload])
      redirect_to admin_recsports_path, notice: "RecSports sync completed."
    rescue StandardError => e
      redirect_to admin_recsports_path, alert: e.message
    end

    def browser_sync
      if request.options?
        head :ok
        return
      end

      credential = RecsportsCredential.find_by(browser_sync_token: params[:token].to_s)
      unless credential
        render json: { error: "Invalid browser sync token." }, status: :unauthorized
        return
      end

      snapshot = parse_snapshot(params[:snapshot])
      Recsports::Importer.new(snapshot: snapshot).call
      credential.update!(last_checked_at: Time.current, last_error: nil, active: true)

      render json: {
        status: "ok",
        imported_events: Array(snapshot["events"]).size
      }
    rescue StandardError => e
      credential&.update(last_error: e.message, active: false)
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def start_browser_sync
      credential = RecsportsCredential.first
      if credential.blank?
        redirect_to admin_recsports_path, alert: "Configure RecSports access first."
        return
      end

      unless credential.browser_assisted?
        redirect_to admin_recsports_path, alert: "Set RecSports access mode to Browser assisted first."
        return
      end

      Recsports::BrowserSyncLauncher.new(
        credential: credential,
        app_url: request.base_url
      ).call

      redirect_to admin_recsports_path, notice: "Browser sync launched. A Chrome window should open on this machine. Complete Microsoft and Duo there, then return to the sync terminal window if prompted."
    rescue StandardError => e
      redirect_to admin_recsports_path, alert: e.message
    end

    private

    def credential_params
      params.require(:recsports_credential).permit(:access_mode, :form_url, :username, :password, :active)
    end

    def parse_snapshot(raw_snapshot)
      return {} if raw_snapshot.blank?
      return raw_snapshot if raw_snapshot.is_a?(Hash)
      return raw_snapshot.to_unsafe_h if raw_snapshot.is_a?(ActionController::Parameters)

      JSON.parse(raw_snapshot)
    rescue JSON::ParserError
      {}
    end

    def set_browser_sync_headers
      response.set_header("Access-Control-Allow-Origin", "*")
      response.set_header("Access-Control-Allow-Methods", "POST, OPTIONS")
      response.set_header("Access-Control-Allow-Headers", "Content-Type")
    end
  end
end
