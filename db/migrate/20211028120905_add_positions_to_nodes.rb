class AddPositionsToNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :position, :integer, default: 0
  end
end
