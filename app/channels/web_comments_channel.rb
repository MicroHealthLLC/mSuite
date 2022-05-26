class WebCommentsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "web_comments_channel#{params[:room]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
