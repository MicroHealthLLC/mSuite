class Category < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  enum status: { active: 0, archived: 1 }
  
  def self.ransackable_associations(auth_object = nil)
    []
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "name", "status", "updated_at"]
  end
end
