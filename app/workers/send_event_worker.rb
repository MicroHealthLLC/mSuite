class SendEventWorker
  include Sidekiq::Worker

  def perform(node_id)
    node = Node.find_by_id(node_id)
    ActionCable.server.broadcast "web_notifications_channel#{node.mindmap_id}", message: "Event Trigger", node: node
  end
end
