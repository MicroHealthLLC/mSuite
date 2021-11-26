class Stage < ApplicationRecord
  include ActiveModel::Dirty
  has_many :nodes, dependent: :delete_all
  belongs_to :mindmap, optional: true
  default_scope { order('position ASC') }

  validates :title, presence: true
  validates_uniqueness_of :title, scope: :mindmap_id, :case_sensitive => false
  before_create :set_position
  before_update :position_updated, if: Proc.new { |p| p.will_save_change_to_attribute?(:position)}

  def set_position
    self.position = self.mindmap.stages.last.position + 1 rescue 0
  end

  def position_updated
    if self.position > self.position_was
      self.mindmap.stages.where("position <= ?", position).where.not(id: id).where.not("position < ?", position_was).update_all("position = position - 1")

    elsif  self.position < self.position_was
      self.mindmap.stages.where("position >= ?", position).where.not(id: id).where.not("position > ?", position_was).update_all("position = position + 1")
    end

  end
end
