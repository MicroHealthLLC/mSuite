class AddSprintToNode < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :is_sprint, :boolean, default: false
  end
end
