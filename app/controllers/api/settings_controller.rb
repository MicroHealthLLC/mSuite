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
      render json: {}, status: 422
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
      :passwords_key
    )
  end
end
