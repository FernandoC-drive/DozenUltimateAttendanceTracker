require 'rails_helper'

RSpec.describe AttendancesController, type: :controller do
  let(:user) { User.create!(email: 'test@tamu.edu', name: 'Tester', password: 'password', coach: false) }

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to(new_session_path) 
      end
    end

    context "when logged in" do
      before do
        session[:user_id] = user.id 
      end

      it "returns a successful response" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "assigns @attendances" do
        get :index
        expect(assigns(:attendances)).not_to be_nil
      end
    end
  end
end