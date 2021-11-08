class AddWidthSizeToNode < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :node_width, :integer, default: 0
  end
end
