class AddElementTypeToNodes < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :element_type, :string
    add_column :nodes, :element_width, :float
    add_column :nodes, :element_height, :float
  end
end
