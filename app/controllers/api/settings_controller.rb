class Api::SettingsController < AuthenticatedController
  before_action :require_admin
  before_action :set_resource

  def index
    render json: @settings
  end

  def update
    if @settings.update(setting_params)
      render json: @settings
    else
      render json: @settings.errors.full_messages, status: 422
    end
  end

  private
  def set_resource
    @settings = Setting.first
  end

  def setting_params
    params.require(:settings).permit(
      :office365_key,
      :office365_secret,
      :google_map_key,
      :google_oauth_key,
      :google_oauth_secret,
      :google_recaptcha_site_key,
      :host_url,
      :passwords_key,
      :beta_status,
      :beta_url,
      :public_url,
      :terms_url,
      :privacy_url,
      :about_url,
      :failed_password_attempts,
      :lockout_period,
      :permanent_lock
    )
  end
end
