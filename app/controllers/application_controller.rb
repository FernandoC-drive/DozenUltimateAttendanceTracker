class ApplicationController < ActionController::Base
  allow_browser versions: :modern


  def current_user
    @current_user ||= super || User.find_by(id: session[:user_id])
  end
  helper_method :current_user

  def require_login!
    redirect_to new_session_path, alert: "Please sign in." unless current_user
  end
end