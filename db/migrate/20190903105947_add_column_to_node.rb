class AddColumnToNode < ActiveRecord::Migration[5.2]
  def change
    add_column  :nodes, :is_disabled, :bool, default: false
  end
end
