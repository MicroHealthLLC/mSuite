class MindmapUser < ApplicationRecord
  belongs_to :shared_user, class_name: 'User', foreign_key: 'user_id'
  belongs_to :mindmap
end
