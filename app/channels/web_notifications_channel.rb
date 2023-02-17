class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "web_notifications_channel#{params[:room]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
    GC.start
  end
  def receive(data)
    ActionCable.server.broadcast("web_notifications_channel#{params[:room]}", data)
  end

  def release_memory
    GC.start
  end
end
