require 'rails_helper'

RSpec.describe AttendancesController, type: :controller do
  let(:player) { User.create!(email: 'player@tamu.edu', name: 'Player', password: 'password', coach: false) }
  let(:coach) { User.create!(email: 'coach@tamu.edu', name: 'Coach', password: 'password', coach: true) }

  describe "GET #index" do
    context "when not logged in" do
      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as a player" do
      before { session[:user_id] = player.id }

      it "rescues invalid dates and defaults to current date" do
        get :index, params: { date: "this-is-not-a-date" }
        expect(assigns(:selected_date)).to eq(Date.current)
      end

      it "loads the monthly view by default" do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:view_mode)).to eq("monthly")
      end

      it "filters by daily view with a specific date" do
        get :index, params: { view: 'daily', date: '2026-02-16' }
        expect(assigns(:view_mode)).to eq("daily")
        expect(assigns(:selected_date)).to eq(Date.parse('2026-02-16'))
      end

      it "filters by weekly view" do
        get :index, params: { view: 'weekly' }
        expect(assigns(:view_mode)).to eq("weekly")
      end

      it "handles invalid dates gracefully" do
        get :index, params: { date: 'not-a-real-date' }
        expect(assigns(:selected_date)).to eq(Date.current)
      end
    end
  end
end