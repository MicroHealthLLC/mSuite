class CallbacksController < Devise::OmniauthCallbacksController
  # skip_before_action :verify_authenticity_token

  def office365
    check_omniauth_auth
  end

  def google_oauth2
    check_omniauth_auth
  end

  private

  def check_omniauth_auth
    @user = User.from_omniauth(request.env["omniauth.auth"])
    redirect_to new_user_session_path, alert: "You dont have access rights!" and return if @user.nil?
    sign_in_and_redirect(@user)
  end
end
