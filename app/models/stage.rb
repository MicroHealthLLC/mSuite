class Stage < ApplicationRecord
  has_many :nodes, dependent: :delete_all
  belongs_to :mindmap, optional: true

  validates :title, presence: true
  validates_uniqueness_of :title, scope: :mindmap_id, :case_sensitive => false
end
