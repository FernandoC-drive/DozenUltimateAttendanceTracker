class MembersController < ApplicationController
  before_action :set_member, only: %i[ show edit update ]

  # GET /members or /members.json
  def index
    @members = Member.all
  end

  # GET /members/1 or /members/1.json
  def show
  end

  # GET /members/new
  def new
    @member = Member.new
  end

  # GET /members/1/edit
  def edit
  end

  # POST /members or /members.json
  def create
    @member = Member.new(member_params)

    respond_to do |format|
      if @member.save
        format.html { redirect_to @member, notice: "Member was successfully created." }
        format.json { render :show, status: :created, location: @member }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /members/1 or /members/1.json
  def update
    respond_to do |format|
      if @member.update(member_params)
        format.html { redirect_to @member, notice: "Member was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @member }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @member.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /members/1 or /members/1.json
  def destroy
    # Security check
    unless current_user.coach?
      redirect_to root_path, alert: "You are not authorized to perform this action."
      return
    end

    # Grab the ID from the dropdown IF the URL is our placeholder
    target_id = params[:id] == 'placeholder' ? params[:player_to_delete] : params[:id]

    user = User.find(target_id)
    
    if user.destroy
      redirect_back(fallback_location: root_path, notice: "#{user.name} and all associated data have been permanently deleted.")
    else
      redirect_back(fallback_location: root_path, alert: "Failed to delete user.")
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_member
      @member = Member.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def member_params
      params.expect(member: [ :first_name, :last_name, :email, :role ])
    end
end
