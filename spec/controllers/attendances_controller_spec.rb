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

      it "allows viewing other players when no filter is applied" do
        other = User.create!(email: 'other@tamu.edu', name: 'Other', password: 'password')
        Attendance.create!(player: other, date: Date.current, days_attended: 1)
        Attendance.create!(player: player, date: Date.current, days_attended: 1)
        get :index
        names = assigns(:attendances).map { |a| a.player.name }
        expect(names).to include('Other', player.name)
      end

      it "can filter to a specific player and still calculate percent" do
        Attendance.create!(player: player, date: Date.current, attended: true, days_attended: 1)
        get :index, params: { player_id: player.id }
        expect(assigns(:selected_player)).to eq(player)
        expect(assigns(:percent_attended)).to be_a(Float)
      end

      describe "PATCH #toggle" do
        it "does not allow players to change attendance" do
          att = Attendance.create!(player: player, date: Date.current, attended: false, days_attended: 0)
          patch :toggle, params: { id: att.id }
          att.reload
          expect(att.attended).to be_falsey
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "when logged in as a coach" do
      before { session[:user_id] = coach.id }

      it "loads list of players" do
        u = User.create!(email: 'p2@tamu.edu', name: 'P2', password: 'password', role: :player)
        get :index
        expect(assigns(:players)).to include(u)
      end

      it "can filter by player_id and set percent and calendar data" do
        p = User.create!(email: 'p3@tamu.edu', name: 'P3', password: 'password', role: :player)
        Attendance.create!(player: p, date: Date.current, attended: true, days_attended: 1)
        get :index, params: { player_id: p.id, view: 'calendar' }
        expect(assigns(:selected_player)).to eq(p)
        expect(assigns(:percent_attended)).to eq( (1.0 / Date.current.end_of_month.day * 100).round(1) )
        expect(assigns(:calendar_attendances)).to be_a(Hash)
      end

      it "defaults to the first player when no selection is made" do
        # create a couple of players so the default has something to pick
        p1 = User.create!(email: 'first@tamu.edu', name: 'AAA', password: 'password', role: :player)
        p2 = User.create!(email: 'second@tamu.edu', name: 'BBB', password: 'password', role: :player)

        get :index, params: { view: 'calendar' }
        expect(assigns(:selected_player)).to eq(User.where(role: :player).order(:name).first)
      end

      describe "PATCH #toggle" do
        it "toggles an existing attendance" do
          att = Attendance.create!(player: player, date: Date.current, attended: false, days_attended: 0)
          patch :toggle, params: { id: att.id }
          expect(att.reload.attended).to be_truthy
        end

        it "creates a new attendance when toggled by date/player" do
          patch :toggle, params: { date: Date.current, player_id: player.id }
          expect(Attendance.where(player: player, date: Date.current).exists?).to be(true)
        end
      end
    end
  end
end