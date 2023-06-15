class Stage < ApplicationRecord
  include ActiveModel::Dirty
  include EncryptionConcern, DecryptionConcern
  has_many :nodes, dependent: :delete_all
  belongs_to :mindmap, optional: true
  default_scope { order('position ASC') }

  validates :title, presence: true
  validates_uniqueness_of :title, scope: :mindmap_id, :case_sensitive => false
  before_create :set_position
  before_create :encrypt_attributes, if: :check_private?
  before_update :encrypt_attributes, if: :check_private?
  before_update :position_updated, if: Proc.new { |p| p.will_save_change_to_attribute?(:position)}
  before_destroy :stage_positions_after_destroy
  
  def decryption
    return decrypt_mindmap_attr if self.mindmap.is_private?
    self
  end

  def encrypt_attributes
    encrypt_stage
  end

  def to_json
    decrypt_fields
    self.as_json
  end

  def decrypt_fields
    return unless self.mindmap.is_private?
    self.title = EncryptionService.decrypt(self.title)
    self.stage_color = EncryptionService.decrypt(self.stage_color)
  end

  def check_private?
    return self.mindmap.is_private?
  end
  
  def set_position
    if self.position > 0 && self.position <= self.mindmap.stages.last.position
      self.mindmap.stages.where("position >= ?", self.position).where.not(id: id).update_all("position = position + 1")
    else
      self.position = self.mindmap.stages.last.position + 1 rescue 0
    end

  end

  def position_updated
    if self.position > self.position_was
      self.mindmap.stages.where("position <= ?", position).where.not(id: id).where.not("position < ?", position_was).update_all("position = position - 1")

    elsif  self.position < self.position_was
      self.mindmap.stages.where("position >= ?", position).where.not(id: id).where.not("position > ?", position_was).update_all("position = position + 1")
    end

  end
  def stage_positions_after_destroy
    self.mindmap.stages.where("position >= ?", position).update_all("position = position - 1")
  end
end
