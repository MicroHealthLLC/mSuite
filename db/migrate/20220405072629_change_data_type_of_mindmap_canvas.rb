class ChangeDataTypeOfMindmapCanvas < ActiveRecord::Migration[5.2]
  def change
    change_column :mindmaps, :canvas, :longtext
  end
end
