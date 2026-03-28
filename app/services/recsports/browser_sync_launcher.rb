require "rbconfig"

module Recsports
  class BrowserSyncLauncher
    def initialize(credential:, app_url:)
      @credential = credential
      @app_url = app_url
    end

    def call
      pid = Process.spawn(
        launcher_env,
        RbConfig.ruby,
        script_path.to_s,
        chdir: Rails.root.to_s,
        out: log_path.to_s,
        err: log_path.to_s
      )

      Process.detach(pid)
      pid
    end

    private

    def launcher_env
      ENV.to_h.merge(
        "APP_URL" => @app_url,
        "BUNDLE_GEMFILE" => Rails.root.join("Gemfile").to_s,
        "RECSPORTS_BROWSER_TOKEN" => @credential.browser_sync_token.to_s,
        "RECSPORTS_START_URL" => @credential.form_url.to_s
      )
    end

    def script_path
      Rails.root.join("script", "recsports_browser_sync.rb")
    end

    def log_path
      Rails.root.join("log", "recsports_browser_sync.log")
    end
  end
end
