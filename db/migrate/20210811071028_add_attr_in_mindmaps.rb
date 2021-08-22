class AddAttrInMindmaps < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :user_id, :bigint
    add_column :mindmaps, :status, :integer, default: 0
  end
end
