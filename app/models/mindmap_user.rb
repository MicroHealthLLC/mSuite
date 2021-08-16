class MindmapUser < ApplicationRecord
  belongs_to :user
  belongs_to :mindmap
end
