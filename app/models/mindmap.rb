class Mindmap < ApplicationRecord
  has_many :nodes, dependent: :destroy
  has_many_attached :node_files, dependent: :destroy

  def to_json
    attach_files = []
    if self.node_files.attached?
      attach_files = self.node_files.map do |file| 
        {
          id: file.id, 
          uri: Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
        }
      end
    end
    
    self.as_json.merge(
      nodes: self.nodes.map(&:to_json), 
      attach_files: attach_files
    ).as_json
  end

  def compute_child
    center_node = {"id"=> 0, "name"=> self.name, "children"=> []}
    compute_child_nodes(center_node)
    center_node
  end

  def reset_mindmap
    self.nodes.destroy_all
    self.node_files.map(&:purge)
    self.update_columns(
      name: "Central Idea",
      description: ""
    )
  end

  private
  def compute_child_nodes(node)
    node["children"] = self.nodes.where(parent_node: node["id"]).order(export_index: :asc).map(&:as_json)
    node["children"].each{|nod| compute_child_nodes(nod)}
  end
end
