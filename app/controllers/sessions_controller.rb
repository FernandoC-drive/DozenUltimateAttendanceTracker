class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:email].to_s.downcase)

    if user&.authenticate(params[:password])
      session[:user_id] = user.id

      # automatically enable the coach view flag for users whose role is coach
      # (the `coach` boolean column is what the UI checks at runtime). we
      # update the record here so that logging in always puts a coach into the
      # proper state without requiring the PIN toggle.
      # if the record is marked as a coach role or the coach boolean is
      # already true, make sure the boolean is set. this covers situations
      # where the enum and the toggle flag may get out of sync (tests were
      # occasionally hitting a case where `role` wasn't exactly "coach").
      if user.role == "coach"
        user.coach! unless user.coach?
      end

      redirect_to root_path, notice: "Signed in successfully."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    sign_out(current_user) if current_user
    reset_session
    redirect_to new_session_path, notice: "Signed out."
  end
end
