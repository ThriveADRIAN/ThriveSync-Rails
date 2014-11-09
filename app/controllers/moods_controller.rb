class MoodsController < ApplicationController
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  #load_and_authorize_resource
  check_authorization

  before_action :set_mood, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_rails_user!

  Time.zone = 'EST'
  
  # GET /moods
  # GET /moods.json
  def index
    authorize! :manage, Mood
    authorize! :read, Mood
    if $PARSE_ENABLED
      @rails_user = RailsUser.find_by_id(params[:rails_user_id])
      if @rails_user == nil
        @moods = Mood.where(user_id: current_rails_user.id)
      elsif @rails_user != nil
        @moods = Mood.where(user_id: @rails_user.id)
      end
    end

    respond_to do |format|
      format.html
      format.json { render :json => @moods, status: 200 }
      format.xml { render :xml => @moods, status: 200 }
    end
  end

  # GET /moods/1
  # GET /moods/1.json
  def show
    authorize! :manage, Mood
    authorize! :read, Mood
    respond_to do |format|
      format.html
      format.json { render :json =>  @mood, status: 200 }
      format.xml { render :xml => @mood, status: 200 }
    end
  end

  # GET /moods/new
  def new
    authorize! :manage, Mood
    @mood= Mood.new
  end

  # GET /moods/1/edit
  def edit
    authorize! :manage, Mood
  end

  # POST /moods
  # POST /moods.json
  def create
    authorize! :manage, Mood
    @mood = Mood.new(mood_params)
    @mood.user_id = current_rails_user.id
    @mood.update_attribute(:timestamp, DateTime.now.in_time_zone)
    
    respond_to do |format|
      if @mood.save && $PARSE_ENABLED

        # Create new Mood object then write atributes to Parse
        parse_mood = Parse::Object.new("Mood")
        parse_mood["moodRating"] = @mood.mood_rating
        parse_mood["anxietyRating"] = @mood.anxiety_rating
        parse_mood["irritabilityRating"] = @mood.irritability_rating
        parse_mood["rails_user_id"] = @mood.user_id.to_s
        parse_mood["rails_id"] = @mood.id.to_s
        parse_mood.save

        # Retrieve User with corresponding Rails User ID
        user = Parse::Query.new("_User").eq("rails_user_id", @mood.user_id.to_s).get.first
        
        # Set Parse User ID in Rails
        @mood.parse_user_id = user["objectId"]
        @mood.save
        
        # Set Parse User ID for Mood Entry
        parse_mood["user_id"] = user["objectId"]
        parse_mood.save

        # Find the beginning of the same day as Mood Entry creation date
        # and the beginning of the next day.  This is to be used to find
        # dates in between... Meaning on the same day
        date_check_begin = parse_mood["createdAt"].to_date
        date_check_end =  date_check_begin.tomorrow
        date_check_begin = Parse::Date.new(date_check_begin)
        date_check_end = Parse::Date.new(date_check_end)


        # Set UserData entry for Mood Entry
        user_data = user_data_query = Parse::Query.new("UserData").tap do |q|
          q.eq("UserID", parse_mood["user_id"])
          q.greater_than("createdAt", date_check_begin)
          q.less_than("createdAt", date_check_end)
        end.get.first

        if user_data == nil
          user_data = Parse::Object.new("UserData")
        end

        if user_data["Mood"] == nil
          user_data["Mood"] = Array.new
        end

        if user_data["Mood"].count < 3
          user_data["Mood"] << parse_mood.pointer
          user_data["UserID"] = parse_mood["user_id"]  
          user_data.save

          # Add UserData entry to User Entry
          if user["UserData"] == nil
            user["UserData"] = Array.new
          end

          if !user["UserData"].include?(user_data.pointer)
            user["UserData"] << user_data.pointer
            user.save
          end

          format.html { redirect_to moods_url, notice: 'Mood Entry was successfully tracked.' }
          format.json { render :show, status: :created, location: moods_url }
        else
          parse_mood.parse_delete
          @mood.destroy
          format.html { redirect_to moods_url, notice: 'Mood Entry not created.  You already have three for this day.' }
        end
        
      else
        format.html { render :new }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /moods/1
  # PATCH/PUT /moods/1.json
  def update
    authorize! :manage, Mood
    respond_to do |format|
      if @mood.update(mood_params)
        format.html { redirect_to moods_url, notice: 'Mood Entry was successfully updated.' }
        format.json { render :show, status: :ok, location: moods_url }

        if $PARSE_ENABLED
          parse_mood = Parse::Query.new("Mood").eq("rails_id", @mood.id.to_s).get.first

          parse_mood["moodRating"] = @mood.mood_rating
          parse_mood["anxietyRating"] = @mood.anxiety_rating
          parse_mood["irritabilityRating"] = @mood.irritability_rating
          parse_mood["rails_user_id"] = @mood.user_id.to_s
          parse_mood["rails_id"] = @mood.id.to_s
          parse_mood.save
        end

      elsif false #This will never happen as the user cannot edit for now.
        format.html { render :edit }
        format.json { render json: @mood.errors, status: :unprocessable_entity }

      else
        format.html { redirect_to @mood, notice: 'Mood Entry was not updated... Try again???' }
        format.json { render json: @mood.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /moods/1
  # DELETE /moods/1.json
  def destroy
    authorize! :manage, Mood
    @mood.destroy
    respond_to do |format|

      if $PARSE_ENABLED
        parse_mood = Parse::Query.new("Mood").eq("rails_id", @mood.id.to_s).get.first
        user_data = user_data_query = Parse::Query.new("UserData").tap do |q|
          q.eq("UserID", parse_mood["user_id"])
          q.value_in("Mood", [parse_mood.pointer])
        end.get.first

        user_data["Mood"].delete(parse_mood.pointer)
        if user_data["Mood"] == []
          user_data["Mood"] = nil
        end
        user_data.save
        parse_mood.parse_delete

        if user_data["Mood"] == nil && user_data["Sleep"] == nil && user_data["SelfCare"] == nil && user_data["Journal"] == nil
          user = Parse::Query.new("_User").eq("rails_user_id", @mood.user_id.to_s).get.first
          user["UserData"].delete(user_data.pointer)
          if user["UserData"] == []
            user["UserData"] = nil
          end
          user_data.parse_delete
          user.save
        end
      end

      format.html { redirect_to moods_url, notice: 'Mood Entry was successfully removed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_mood
      @mood = Mood.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def mood_params
      params.require(:mood).permit(:mood_rating, :anxiety_rating, :irritability_rating)
    end
end

