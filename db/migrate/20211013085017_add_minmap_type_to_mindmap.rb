class AddMinmapTypeToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :mm_type, :integer, default: 0, null: false
    add_column :nodes, :stage_id, :integer
  end
end
