class AddParentIdToMindmaps < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :parent_id, :integer
  end
end
