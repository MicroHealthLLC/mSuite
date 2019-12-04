namespace :nodes do

  desc "add default export indexes to mindmap nodes"
  task add_export_indexes_to_nodes: :environment do
    Mindmap.find_each do |mindmap|
      mindmap.nodes.where(parent_node: 0).each_with_index do |node, index|
        assign_export_indexes(node, index)
      end 
    end
  end

  def assign_export_indexes(node, index)
    node.update_column('export_index', index)
    Node.where(parent_node: node.id).each_with_index do |nod, jindex|
      assign_export_indexes(nod, jindex)
    end
  end
end
