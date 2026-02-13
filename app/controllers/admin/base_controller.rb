module Admin
  class BaseController < ApplicationController
    before_action :require_login!
    before_action :require_coach!

    private

    def require_coach!
      return if current_user&.coach?

      redirect_to root_path, alert: "Unauthorized"
    end
  end
end
