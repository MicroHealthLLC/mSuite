class AddStandaloneToNode < ActiveRecord::Migration[6.1]
  def change
    add_column :nodes, :standalone, :boolean, default: false
  end
end
