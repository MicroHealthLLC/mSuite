class Node < ApplicationRecord
  include ActiveModel::Dirty

  default_scope { order('position ASC') }

  belongs_to :mindmap, optional: true
  belongs_to :stage, optional: true

  has_many_attached :node_files, dependent: :destroy

  before_create :set_default_export_index

  after_update :parent_changed, if: Proc.new { |p| p.saved_change_to_attribute? :parent_node }
  after_update :disablity_changed, if: Proc.new { |p| p.saved_change_to_attribute? :is_disabled }

  before_update :position_changed, if: Proc.new { |p| p.will_save_change_to_attribute?(:position) || p.will_save_change_to_attribute?(:stage_id) }
  before_destroy :position_updated, if: :validate_kanban
  validates :title, uniqueness: true, if: :validate_title

  def validate_title
    return self.mindmap.mm_type == "tree_map"
  end

  def validate_kanban
    return self.mindmap.mm_type == "kanban"
  end

  def to_json
    parent = ''
    if self.parent_node == 0 || self.parent_node == nil
      parent = Mindmap.find_by_id(self.mindmap_id).name
    else
      parent = Node.find_by_id(self.parent_node).title
    end
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
                       attach_files: attach_files,
                       status: stage.try(:title),
                       parent: parent
                       ).as_json
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
      temp_node.line_color = parent.line_color

      # duplicate node attachments
      nod.node_files.each do |file|
        temp_node.node_files.attach(file.blob)
      end

      temp_node.save
      duplicate_child_nodes(Node.where(parent_node: nod.id), temp_node)

      temp_node.update_columns(
        parent_node: parent.id
      )
    end
  end

  def duplicate_files(clon_id)
    clon = Node.find_by(id: clon_id)
    if clon and clon.node_files.present?
      clon.node_files.each do |file|
        self.node_files.attach(file.blob)
      end
    end
  end

  def duplicate_attributes(clon_id)
    clon = Node.find_by(id: clon_id)
    if clon.present?
      self.update_columns(
        is_disabled: clon.is_disabled,
        hide_children: clon.hide_children,
        hide_self: clon.hide_self
      )
    end
  end

  def set_default_export_index
    self.export_index = self.mindmap.nodes.where(parent_node: self.parent_node).count if self.mindmap.simple?
    self.position = self.stage.nodes.last.position + 1 rescue 0 if self.stage.present?
  end

  def update_export_order(old_i, new_i)
    small = old_i > new_i ? new_i : old_i
    big = old_i > new_i ? old_i : new_i
    peers = self.mindmap.nodes
              .where(parent_node: self.parent_node)
              .where.not(id: self.id)
              .where("export_index BETWEEN (?) AND (?)", small, big)
    if new_i < old_i
      peers.update_all("export_index = export_index + 1")
    else
      peers.update_all("export_index = export_index - 1")
    end
    self.update_columns(export_index: new_i)
  end

  def position_changed
    if self.stage_id_changed?
      stage_previous = Stage.find(self.stage_id_was)
      stage_previous.nodes.where("position > ?", self.position_was).update_all("position = position - 1")
      self.stage.nodes.where("position >= ?", position).where.not(id: id).update_all("position = position + 1")

    elsif self.position > self.position_was
      self.stage.nodes.where("position <= ?", position).where.not(id: id).where.not("position < ?", position_was).update_all("position = position - 1")

    elsif  self.position < self.position_was
      self.stage.nodes.where("position >= ?", position).where.not(id: id).where.not("position > ?", position_was).update_all("position = position + 1")

    end
  end

  def position_updated
    self.stage.nodes.where("position >= ?", position).update_all("position = position - 1")
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
