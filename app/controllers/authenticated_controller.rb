class AuthenticatedController < ApplicationController
  protect_from_forgery with: :exception, prepend: true, unless: -> { request.format.json? }
  #before_action :authenticate_user!
end
