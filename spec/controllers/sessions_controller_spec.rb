require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { User.create!(email: 'test@tamu.edu', name: 'Tester', password: 'password', role: :player) }

  describe "GET #new" do
    it "renders the login page successfully" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    it "logs in a user with valid credentials" do
      post :create, params: { email: user.email, password: 'password' }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(root_path)
    end

    it "enables the coach flag on login when the user has a coach role" do
      coach_user = User.create!(
        email: 'coachlogin@tamu.edu',
        name: 'Logging Coach',
        password: 'password123',
        role: :coach,
        coach: false # start false to simulate not-yet-enabled state
      )

      post :create, params: { email: coach_user.email, password: 'password123' }
      # debug information to understand why update might not occur
      puts "[debug] after post, session user = #{session[:user_id]}, role=#{coach_user.role}, coach=#{coach_user.coach}"
      coach_user.reload
      puts "[debug] after reload, role=#{coach_user.role}, coach=#{coach_user.coach}"

      expect(session[:user_id]).to eq(coach_user.id)
      # make sure the user really has the coach role before we check the flag
      expect(coach_user.role).to eq("coach")
      expect(coach_user.coach).to be true
    end

    it "rejects login with invalid credentials" do
      post :create, params: { email: user.email, password: 'wrongpassword' }
      expect(session[:user_id]).to be_nil
      

      expect(response).to have_http_status(:unprocessable_entity) 
      expect(flash.now[:alert]).to eq("Invalid email or password.")
    end
  end

  describe "DELETE #destroy" do
    before do
      session[:user_id] = user.id
    end

    it "clears the session and redirects to login" do
      delete :destroy
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq("Signed out.")
    end
  end
end