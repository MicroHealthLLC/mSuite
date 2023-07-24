class HomeController < AuthenticatedController
  before_action :reset_session, only: :index
  layout "file_manager"

  def index
  end

  def page_404
  end

  def socket_status
    ActionCable.server.broadcast("socket_status_channel", {message: 'Socket is working'} )
    render json: {}, status: 200
  end

  private

  def reset_session
    session[:mindmap_id] = " "
  end
end
