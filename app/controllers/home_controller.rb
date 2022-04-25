class HomeController < AuthenticatedController
  before_action :reset_session, only: :index
  layout "file_manager"

  def index
  end

  def page_404
  end

  private

  def reset_session
    session[:mindmap_id] = " "
  end
end
