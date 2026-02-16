class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env["omniauth.auth"]
    
    user = User.from_google(
      email: auth.info.email,
      full_name: auth.info.name,
      uid: auth.uid,
      avatar_url: auth.info.image
    )

    if user.present?
      sign_out_all_scopes
      flash[:success] = "Successfully authenticated from Google account."
      sign_in_and_redirect user, event: :authentication
    else
      flash[:alert] = "Authentication failed."
      redirect_to new_session_path
    end
  end
  
  protected
  def after_omniauth_failure_path_for(_scope)
    new_session_path
  end
  def after_sign_in_path_for(resource_or_scope)
    stored_location_for(resource_or_scope) || root_path
  end
end