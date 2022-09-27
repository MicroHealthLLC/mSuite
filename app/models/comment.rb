class Comment < ApplicationRecord
  include ActiveModel::Dirty
  belongs_to :mindmap, optional: true
  validates :message, presence: true
end
