class SocketStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from "socket_status_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
