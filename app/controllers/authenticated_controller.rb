class AuthenticatedController < ApplicationController
  protect_from_forgery with: :exception, prepend: true
  before_action :authenticate_user!
end
