class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  enum status: { active: 0, archived: 1 }
end
