class AddImageToMindmaps < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :image , :binary
  end
end
