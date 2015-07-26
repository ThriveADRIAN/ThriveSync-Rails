class MoodsController < ApplicationController
  resource_description do
    short 'Mood Entries'
    desc <<-EOS
      == Long description
        Mood Entries include:
          Mood Rating
          Anxiety Rating
          Irritability Rating
          Timestamp

      ===Sample JSON Output:
          {
            "moods": [
              {
                "id": 2712,
                "mood_rating": 4,
                "anxiety_rating": 1,
                "irritability_rating": 1,
                "timestamp": "2014-10-27 09:59:00 -0400",
                "created_at": "2014-10-27 05:59:41 -0400",
                "updated_at": "2014-10-27 05:59:41 -0400",
                "user_id": 24
              }
            ]
          }
      EOS
    api_base_url ""
    formats ['html', 'json']
  end

  def_param_group :moods_data do
    param :mood, Hash , :desc => "Mood", :required => false do
      param :mood_rating, :number, :desc => "[['Severely Depressed', 1], ['Moderately Depressed', 2], ['Mildly Depressed', 3], ['Baseline',4], ['Mildly Elevated',5], ['Moderately Elevated', 6], ['Severely Elevated',7]]", :required => true
      param :anxiety_rating, :number, :desc => "[['None', 1], ['Mild', 2], ['Moderate', 3], ['Severe',4]]", :required => true
      param :irritability_rating, :number, :desc => "[['None', 1], ['Mild', 2], ['Moderate', 3], ['Severe',4]]", :required => true
    end
  end

  def_param_group :moods_all do
    param_group :moods_data
    param :timestamp, :undef, :desc => "Timestamp for Mood Entry [DateTime(UTC)]", :required => false
  end

  acts_as_token_authentication_handler_for User

  before_action :set_mood, only: [:show, :edit, :update, :destroy]
  before_action :set_lookback_period, only: [:index]
  before_action :authenticate_user!

  after_filter :verify_authorized,  except: [:index]
  #after_filter :verify_policy_scoped, only: [:index]

  respond_to :html, :js, :json
  
  # GET /moods
  # GET /moods.json
  api! "Show Mood Entries"
  def index
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      @moods = Mood.where(user_id: current_user.id)
      skip_authorization
    elsif @user != nil
      @moods = Mood.where(user_id: @user.id)
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    #@moods = policy_scope(@moods)
   
    respond_to do |format|
      format.html
      format.js
      format.json { render :json => @moods, status: 200 }
    end
  end

  # GET /moods/1
  # GET /moods/1.json
  def show
    authorize! :manage, Mood
    authorize! :read, Mood
    
    respond_to do |format|
      format.html { render :nothing => true }
      format.js
      format.json { render :json =>  @mood, status: 200 }
    end
  end

  # GET /moods/new
  def new
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    @mood= Mood.new

    respond_to do |format|
      format.html { render :nothing => true }
      format.js
      format.json { render :json =>  @mood, status: 200 }
    end
  end

  # GET /moods/1/edit
  api! "Edit Mood Entry"
  param_group :moods_all
  def edit
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    respond_to do |format|
      format.html { render :nothing => true }
      format.js
      format.json { render :json =>  @mood, status: 200 }
    end
  end

  # POST /moods
  # POST /moods.json
  api! "Create Mood Entry"
  param_group :moods_data
  def create
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    @mood = Mood.new(mood_params)
    @mood.user_id = current_user.id
    @mood.timestamp = DateTime.now.in_time_zone
    
    respond_to do |format|
      if @mood.save
        track_mood_created

        current_user.scorecard.update_scorecard('moods')
        flash.now[:success] = "Mood Entry was successfully tracked."
        format.js { render status: :created }
        format.json { render :json => @mood, status: :created }
      else
        flash.now[:error] = "Mood Entry was not tracked... Try again???"
        format.js   { render json: @mood.errors, status: :unprocessable_entity }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /moods/1
  # PATCH/PUT /moods/1.json
  api! "Update Mood Entry"
  param_group :moods_all
  def update
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end
    
    respond_to do |format|
      if @mood.update(mood_params)
        track_mood_updated

        flash.now[:success] = "Mood Entry was successfully updated."
        format.js { render status: 200 }
        format.json { render :json => @mood, status: 200 }
      else
        flash.now[:error] = "Mood Entry was not updated... Try again???"
        format.js   { render json: @mood.errors, status: :unprocessable_entity }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  def delete
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    @mood = Mood.find(params[:mood_id])

    respond_to do |format|
      format.js
    end
  end

  # DELETE /moods/1
  # DELETE /moods/1.json
  api! "Delete Mood Entry"
  def destroy
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end
    
    @mood.destroy
    track_mood_deleted
    
    respond_to do |format|
      flash.now[:success] = "Mood Entry was successfully deleted."
      format.js 
      format.json { head :no_content }
    end
  end

  def cancel
    @user = User.find_by_id(params[:user_id])

    if @user == nil
      skip_authorization
    elsif @user != nil
      if @user.id == current_user.id
        skip_authorization
      else
        authorize @moods
      end
    end

    $current_capture_screen = "Mood"
    
    respond_to do |format|
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mood
      @mood = Mood.find(params[:id])
    end

    def set_lookback_period
      if(params.has_key?(:mood_lookback_period))
        @mood_lookback_period = params[:mood_lookback_period]
      else
        @mood_lookback_period = DEFAULT_LOOKBACK_PERIOD
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def mood_params
      params.fetch(:mood, {}).permit(:mood_rating, :anxiety_rating, :irritability_rating, :timestamp, :mood_lookback_period)
    end

    def track_mood_created
      # Track Mood Creation for Segment.io Analytics
      Analytics.track(
        user_id: @mood.user_id,
        event: 'Created Mood Entry',
        properties: {
          mood_id: @mood.id,
          mood_rating: @mood.mood_rating,
          anxiety_rating: @mood.anxiety_rating,
          irritability_rating: @mood.irritability_rating,
          timestamp: @mood.timestamp
        }
      )
    end

    def track_mood_updated
      # Track Mood Update for Segment.io Analytics
      Analytics.track(
        user_id: @mood.user_id,
        event: 'Updated Mood Entry',
        properties: {
          mood_id: @mood.id,
          mood_rating: @mood.mood_rating,
          anxiety_rating: @mood.anxiety_rating,
          irritability_rating: @mood.irritability_rating,
          timestamp: @mood.timestamp
        }
      )
    end

    def track_mood_deleted
      # Track Mood Deletion for Segment.io Analytics
      Analytics.track(
        user_id: @mood.user_id,
        event: 'Deleted Mood Entry',
        properties: {
        }
      )
    end
end