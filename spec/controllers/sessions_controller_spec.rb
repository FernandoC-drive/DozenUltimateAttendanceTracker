require 'rails_helper'

RSpec.describe SessionsController, type: :controller do
  let(:user) { User.create!(email: 'test@tamu.edu', name: 'Tester', password: 'password') }

  describe "GET #new" do
    it "renders the login page successfully" do
      get :new
      expect(response).to be_successful
    end
  end

  describe "POST #create" do
    let(:user) { User.create!(email: 'manual@tamu.edu', name: 'Manual Login', password: 'password123', coach: false) }

    it "logs in a user with valid credentials" do
      post :create, params: { email: user.email, password: 'password123' }
      expect(session[:user_id]).to eq(user.id)
      expect(response).to redirect_to(root_path)
    end

    it "rejects login with invalid credentials" do
      post :create, params: { email: user.email, password: 'wrongpassword' }
      expect(session[:user_id]).to be_nil
      expect(response).to have_http_status(:unprocessable_entity) # Or check for render :new depending on Rails version
      expect(flash.now[:alert]).to eq("Invalid email or password.")
    end
  end

  describe "GET #new" do
    it "renders the login form" do
      get :new
      expect(response).to have_http_status(:success)
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