module NodeConcern
  extend ActiveSupport::Concern

  def update_node_parent(node)
    if node.parent_node != nil
      node_id = node.parent_node
    else
      node_id = node.id
    end

    is_disabled = []
    parent_node = Node.find_by_id(node_id)
    if parent_node
      child_nodes = Node.where(parent_node: parent_node.id)
      if child_nodes.length != 0
        child_nodes.all.each do |n|
          if node.parent_node != nil
            is_disabled << n.is_disabled
          elsif node_id != nil && node.parent_node == nil
            if node.is_disabled == true
              is_disabled << true
              n.update(is_disabled: true)
            elsif node.is_disabled == false
            end
          end
        end
        if is_disabled.uniq.count == 1
          parent_node.update(is_disabled: is_disabled.include?(true))
        elsif is_disabled.uniq.count == 2
          parent_node.update(is_disabled: false)
        end
      else
        parent_node.update(is_disabled: parent_node.is_disabled)
      end
    end
  end

  def get_time(node)
    eventTime = nil
    if Time.zone.now >= node.startdate - 15 * 60 && Time.zone.now <= node.startdate
      eventTime = Time.zone.now + 1 * 60
    else
      eventTime = node.startdate - 15 * 60
    end
    return eventTime
  end

  def create_worker(node)
    SendEventWorker.perform_at(get_time(node) , node.id) if node.startdate
  end

  def update_worker(node)
    scheduler = Sidekiq::ScheduledSet.new
    if scheduler.size > 0
      scheduler.each do |job|
        if job.klass == 'SendEventWorker' && job.args == [node.id]
          job.reschedule(get_time(node))
        end
      end
    else
      SendEventWorker.perform_at(get_time(node) , node.id)
    end
  end

  def duplicate_child_nodes
    @node.duplicate_attributes(params[:duplicate_child_nodes])
    dup_nodes = Node.where(parent_node: params[:duplicate_child_nodes]).where.not(id: @node.id)
    Node.duplicate_child_nodes(dup_nodes, @node) if dup_nodes.present?
  end

  def del_worker(node)
    queue = Sidekiq::ScheduledSet.new
    queue.each do |job|
      job.delete if (job.klass == 'SendEventWorker' && job.args == [node.id])
    end
  end
end
