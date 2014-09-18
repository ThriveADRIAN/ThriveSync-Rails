class SelfCaresController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  load_and_authorize_resource

  before_action :set_self_care, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  Time.zone = 'EST'
  
  # GET /self_cares
  # GET /self_cares.json
  def index
    @self_cares = SelfCare.where(user_id: current_user.id)

    respond_to do |format|
      format.html
      format.json { render :json => @self_cares, status: 200 }
      format.xml { render :xml => @self_cares, status: 200 }
    end
  end

  # GET /self_cares/1
  # GET /self_cares/1.json
  def show
    respond_to do |format|
      format.html
      format.json { render :json =>  @self_care, status: 200 }
      format.xml { render :xml => @self_care, status: 200 }
    end
  end

  # GET /self_cares/new
  def new
    @self_care= SelfCare.new
  end

  # GET /self_cares/1/edit
  def edit
  end

  # POST /self_cares
  # POST /self_cares.json
  def create
    @self_care = SelfCare.new(self_care_params)
    @self_care.user_id = current_user.id
    
    respond_to do |format|
      if @self_care.save
        format.html { redirect_to self_cares_url, notice: 'Self Care Entry was successfully tracked.' }
        format.json { render :show, status: :created, location: self_cares_url }
      else
        format.html { render :new }
        format.json { render json: @self_care.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /self_cares/1
  # PATCH/PUT /self_cares/1.json
  def update
    respond_to do |format|
      if @self_care.update(self_care_params)
        format.html { redirect_to self_cares_url, notice: 'Self Care Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: self_cares_url }

      elsif false #This will never happen as the user cannot edit for now.
        format.html { render :edit }
        format.json { render json: @self_care.errors, status: :unprocessable_entity }

      else
        format.html { redirect_to @self_care, notice: 'Self Care Entry was not updated... Try again???' }
        format.json { render json: @self_care.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /self_cares/1
  # DELETE /self_cares/1.json
  def destroy
    @self_care.destroy
    respond_to do |format|
      format.html { redirect_to self_cares_url, notice: 'Self Care Entry was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_self_care
      @self_care = SelfCare.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def self_care_params
      params.require(:self_care).permit( :counseling, :medication, :meditation, :exercise)
    end
end


