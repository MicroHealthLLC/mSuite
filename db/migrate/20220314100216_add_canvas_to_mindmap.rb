class AddCanvasToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :canvas, :json
  end
end
