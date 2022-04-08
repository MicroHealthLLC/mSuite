class AddCanvasToMindmapAndAlterTable < ActiveRecord::Migration[5.2]
  def change
    mindmap = Mindmap.new
    if mindmap.has_attribute?(:canvas)
      change_column :mindmaps, :canvas, :longtext
    else
      add_column :mindmaps, :canvas, :longtext
    end
  end
end
