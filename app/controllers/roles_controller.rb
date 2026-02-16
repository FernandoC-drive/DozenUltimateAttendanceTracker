class RolesController < ApplicationController
  before_action :require_login!

  def enable_coach
    # In a production app, you would use ENV['COACH_PIN'] here
    if params[:password] == "howdy"
      current_user.update(coach: true)
      redirect_back fallback_location: root_path, notice: "Coach view enabled."
    else
      redirect_back fallback_location: root_path, alert: "Incorrect Coach PIN."
    end
  end

  def disable_coach
    current_user.update(coach: false)
    redirect_back fallback_location: root_path, notice: "Returned to Player view."
  end
end