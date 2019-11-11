class Node < ApplicationRecord
  belongs_to :mindmap, optional: true
  has_many_attached :node_files

  after_update :parent_changed, if: Proc.new { |p| p.saved_change_to_attribute? :parent_node }
  after_update :disablity_changed, if: Proc.new { |p| p.saved_change_to_attribute? :is_disabled }

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
    self.as_json.merge(attach_files: attach_files).as_json
  end

  def parent_changed
    parent = self.parent_node != 0 ? Node.find_by_id(self.parent_node) : self
    update_parent_attr(Node.where(parent_node: self.id), parent)
  end

  def disablity_changed
    update_disability(Node.where(parent_node: self.id), self.is_disabled)
  end

  def self.duplicate_child_nodes(nodes, parent)
    return if nodes.length == 0

    nodes.each do |nod|
      temp_node = nod.dup
      temp_node.position_x += 50
      temp_node.position_y -= 30
      temp_node.save
      duplicate_child_nodes(Node.where(parent_node: nod.id), temp_node)
      
      temp_node.update_columns(
        parent_node: parent.id,
        line_color: parent.line_color
      )
    end
  end

  private
  
  def update_parent_attr(nodes, parent)
    return if nodes.length == 0
    
    nodes.each do |nod|
      nod.update_columns(line_color: parent.line_color)
      update_parent_attr(Node.where(parent_node: nod.id), nod)
    end
  end

  def update_disability(nodes, ability)
    return if nodes.length == 0
    
    nodes.each do |nod|
      nod.update_columns(is_disabled: ability)
      update_disability(Node.where(parent_node: nod.id), ability)
    end
  end
end
