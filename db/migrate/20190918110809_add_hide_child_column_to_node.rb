class AddHideChildColumnToNode < ActiveRecord::Migration[5.2]
  def change
    add_column  :nodes, :hide_children, :bool, default: false
    add_column  :nodes, :hide_self, :bool, default: false
  end
end
