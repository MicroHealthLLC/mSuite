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
              is_disabled << false
              n.update(is_disabled: false)
            end
          end
        end
        if is_disabled.uniq.count == 1
          parent_node.update(is_disabled: is_disabled.include?(true))
        else is_disabled.uniq.count == 2
          parent_node.update(is_disabled: false)
        end
      else
        parent_node.update(is_disabled: parent_node.is_disabled)
      end
    end
  end
end
