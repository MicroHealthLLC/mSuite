class AddBgColorToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :line_color, :string, default: '#B3FAFF'
  end
end
