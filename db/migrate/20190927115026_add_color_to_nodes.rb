class AddColorToNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :line_color, :string, default: nil
  end
end
