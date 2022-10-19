class Comment < ApplicationRecord
  include ActiveModel::Dirty
  belongs_to :mindmap
  has_many   :replies, class_name: 'Comment', foreign_key: 'parent_comment'
  belongs_to :parent, class_name: 'Comment', foreign_key: 'parent_comment', optional: true
  
  validates :message, presence: true
end
