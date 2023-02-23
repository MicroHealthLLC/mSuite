class Node < ApplicationRecord
  include ActiveModel::Dirty
  include NodeConcern, EncryptionConcern, DecryptionConcern
  default_scope { order('position ASC') }

  belongs_to :mindmap, optional: true
  belongs_to :stage, optional: true

  has_many :children, class_name: 'Node', foreign_key: 'parent_node', dependent: :destroy
  belongs_to :parent, class_name: 'Node', foreign_key: 'parent_node', optional: true

  before_create :set_default_export_index, :create_notification
  before_create :encrypt_attributes, if: :check_private?
  before_create :set_position_slide, if: :validate_presentation
  after_create :create_notification
  after_update :update_childs_position, if: :check_parent_position?
  after_update :parent_changed, if: Proc.new { |p| p.saved_change_to_attribute? :parent_node }
  after_update :disablity_changed, if: Proc.new { |p| p.saved_change_to_attribute? :is_disabled }
  before_update :encrypt_attributes, if: :check_private?
  after_update :encrypt_attributes, if: :check_private?
  before_update :position_changed, if: Proc.new { |p| p.will_save_change_to_attribute?(:position) || p.will_save_change_to_attribute?(:stage_id) }
  before_destroy :position_updated, if: -> { validate_kanban || validate_presentation }
  before_destroy :delete_file, if: :validate_fileshare
  after_update :update_parent_node
  validates_uniqueness_of :title, scope: :mindmap_id, if: :validate_title
  validates_uniqueness_of :description, scope: :mindmap_id, if: :validate_description
  validate :encrypted_title, if: :validate_private_treemap_condition

  def update_parent_node
    self.parent.update(hide_children: true) if self.parent && self.mindmap.mm_type == 'presentation'
  end

  def decryption
    return decrypt_mindmap_attr if self.mindmap.is_private?
    self
  end

  def encrypt_attributes
    encrypt_node
  end
  def check_private?
    return self.mindmap.is_private?
  end

  def set_position
    if mindmap_id.present? && ( position.nil? ||  position == 0 )
      self.position = self.mindmap.nodes.count + 1
    end
  end

  def set_position_slide
    if self.position > 0 && self.position <= self.mindmap.nodes.last.position
      self.mindmap.nodes.where("position >= ?", self.position).where.not(id: id).update_all("position = position + 1")
    elsif self.parent.nil?
      self.position = self.mindmap.nodes.last.position + 1 rescue 0
    end
  end

  def set_children
    if self.parent_node
      node = Node.find_by_id(self.parent_node)
      if node && node.mindmap.id != self.mindmap.id
        self.mindmap_id = node.mindmap.id
      end
    end
  end

  def update_all_colors(color)
    nodes = Mindmap.includes(:nodes).find_by_id(self.mindmap.id).nodes.where(element_type: nil)
    nodes.each do |node|
      node.update(line_color: color)
    end
  end

  def create_notification
    create_worker(self) if self.mindmap.mm_type == 'calendar' || self.mindmap.mm_type == 'todo'
  end

  def validate_private_treemap_condition
    return self.mindmap.is_private? && self.mindmap.tree_map?
  end

  def encrypted_title
    add_errors_to_title(EncryptionService.decrypt(self.title))
  end

  def add_errors_to_title(title)
    nodes = self.mindmap.nodes.map(&:decryption) unless self.mindmap.nodes.empty?
    return if nodes.nil?
    nodes.each do |node|
      errors.add :title, :unprocessable_entity, message: "not unique" if node[:title] == title
    end
  end

  def validate_title
    return self.mindmap && self.mindmap.id != nil && self.mindmap.mm_type == "tree_map" && !self.mindmap.is_private?
  end

  def validate_description
    return self.mindmap && self.mindmap.id != nil && self.mindmap.mm_type == "venndiagram" && !self.mindmap.is_private?
  end

  def validate_kanban
    return self.mindmap&.mm_type == "kanban"
  end

  def validate_presentation
    return self.mindmap&.mm_type == "presentation"
  end

  def validate_fileshare
    return self.mindmap&.mm_type == "fileshare"
  end

  def to_json
    decrypt_fields
    parent_name = ''
    if self.parent_node == 0 || self.parent_node == nil
      parent_name = self.mindmap.name
      parent_name = EncryptionService.decrypt(parent_name) if self.mindmap.is_private?
    else
      parent_name = self.parent&.title
      parent_name = EncryptionService.decrypt(parent) if self.mindmap.is_private?
    end
    status = stage.try(:title)
    status = EncryptionService.decrypt(status) if status && self.mindmap.is_private?
    self.as_json.merge(status: status, parent: parent_name, parent_nod: parent, children: self.children.map(&:to_json)).as_json
  end

  def decrypt_fields
    return unless self.mindmap.is_private?
    self.title = EncryptionService.decrypt(self.title)
    self.description = EncryptionService.decrypt(self.description)
  end

  def parent_changed
    parent = (self.parent_node != 0 && self.parent_node != nil) ? Node.find_by_id(self.parent_node) : self
    update_parent_attr(Node.where(parent_node: self.id), parent)
  end

  def disablity_changed
    unless self.mindmap.mm_type == 'todo'
      update_disability(Node.where(parent_node: self.id), self.is_disabled)
    end
  end

  def self.duplicate_child_nodes(nodes, parent)
    return if nodes.length == 0

    nodes.each_with_index do |nod, index|
      temp_node = nod.dup
      temp_node.position_x = parent.position_x + ((index + 1) * 100)
      temp_node.position_y = parent.position_y + ((index + 1) * 80)
      temp_node.line_color = parent.line_color

      temp_node.save
      duplicate_child_nodes(Node.where(parent_node: nod.id), temp_node)

      temp_node.update_columns(
        parent_node: parent.id
      )
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

    elsif self.stage_id && self.position > self.position_was
      self.stage.nodes.where("position <= ?", position).where.not(id: id).where.not("position < ?", position_was).update_all("position = position - 1")

    elsif self.stage_id && self.position < self.position_was
      self.stage.nodes.where("position >= ?", position).where.not(id: id).where.not("position > ?", position_was).update_all("position = position + 1")

    elsif self.mindmap.mm_type == 'presentation' && self.position > self.position_was
      self.mindmap.nodes.where("position <= ?", position).where.not(id: id).where.not("position < ?", position_was).update_all("position = position - 1")

    elsif self.mindmap.mm_type == 'presentation' && self.position < self.position_was
      self.mindmap.nodes.where("position >= ?", position).where.not(id: id).where.not("position > ?", position_was).update_all("position = position + 1")

    end
  end

  def position_updated
    if self.stage
    self.stage.nodes.where("position >= ?", position).update_all("position = position - 1") if self.stage
    elsif self.position? && self.parent.nil?
      self.mindmap.nodes.where("position >= ?", position).update_all("position = position - 1")
    end
  end

  def delete_file
    File.delete(Rails.root.join('public', 'uploads', self.title))
  end

  def check_parent_position?
    posi_x_perv_changes = self.previous_changes[:position_x]
    return self.mindmap.mm_type == "simple" && self.children&.length > 0 && (posi_x_perv_changes != nil && posi_x_perv_changes&.length > 1)
  end

  def update_childs_position
    return if self.children.length == 0
    self.children.each_with_index do |nod, index|
      if self.position_x < 2820
        nod.position_x = self.position_x - ((index + 1) * 70)
      else
        nod.position_x = self.position_x + ((index + 1) * 70)
      end
      nod.save
    end
  end

  private

  def update_parent_attr(nodes, parent)
    return if nodes.length == 0
    nodes.each do |nod|
      unless(mindmap.mm_type == 'tree_map' || mindmap.mm_type == 'flowmap' || mindmap.mm_type == 'tree_chart')
        nod.update_columns(parent_node: parent.id) if mindmap.mm_type == 'todo'
        nod.update_columns(line_color: parent.line_color)
      end
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
