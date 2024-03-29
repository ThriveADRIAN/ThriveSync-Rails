class ApplicationController < ActionController::Base
  respond_to :html, :json

  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :null_session

  before_filter :set_timezone

  before_filter do
    resource = controller_name.singularize.to_sym
    method = "#{resource}_params"
    params[resource] &&= send(method) if respond_to?(method, true)
  end

  before_filter :configure_devise_params, if: :devise_controller?

  def configure_devise_params
    devise_parameter_sanitizer.for(:sign_up) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation, roles: [])
    end
    devise_parameter_sanitizer.for(:account_update) do |u|
      u.permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, roles: [], :reward_attributes => [:id, :rewards_enabled])
    end
    devise_parameter_sanitizer.for(:password_update) do |u|
      u.permit(:email, :password)
    end
  end

  before_filter :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:accept_invitation).concat [:first_name, :last_name]
  end

  before_filter :record_user_activity

  alias_method :current_user, :current_user # Could be :current_member or :logged_in_user

  ActionController::Renderers.add :json do |json, options|
    unless json.kind_of?(String)
      json = json.as_json(options) if json.respond_to?(:as_json)
      json = JSON.pretty_generate(json, options)
    end

    if options[:callback].present?
      self.content_type ||= Mime::JS
      "#{options[:callback]}(#{json})"
    else
      self.content_type ||= Mime::JSON
      json
    end
  end

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  helper_method :pro_access_granted?

  def app_constants
    respond_to do |format|
      format.json {
        render json: {
                 max_journal_entries: MAX_JOURNAL_ENTRIES,
                 max_mood_entries: MAX_MOOD_ENTRIES,
                 max_self_care_entries: MAX_SELF_CARE_ENTRIES,
                 max_sleep_entries: MAX_SLEEP_ENTRIES,
               }
      }
    end
  end

  protected

  def authenticate_inviter!
    authenticate_user!(:force => true)
  end

  private

  def user_not_authorized
    respond_to do |format|
      flash[:error] = "You are not authorized to perform this action."
      format.html { redirect_to request.headers["Referer"] || root_path }
      format.json { render :status => 401, :json => {:message => "You are not authorized to perform this action."}
      }
      false
    end
  end

  def record_user_activity
    if current_user
      current_user.touch :last_active_at
    end
  end

  def set_timezone
    tz = current_user ? current_user.timezone : nil
    Time.zone = tz || ActiveSupport::TimeZone["Eastern Time (US & Canada)"]
  end

  # Overwriting the sign_in redirect path method
  def after_sign_in_path_for(resource_or_scope)
    track_user_login
    root_path
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    track_user_logout
    root_path
  end

  def track_user_login
    # Track User Login for Segment.io Analytics
    Analytics.track(
      user_id: current_user.id,
      event: 'Logged In',
      properties: {
      }
    )
  end

  def track_user_logout
    # Track User Logout for Segment.io Analytics
    Analytics.track(
      user_id: current_user,
      event: 'Logged Out',
      properties: {
      }
    )
  end
end