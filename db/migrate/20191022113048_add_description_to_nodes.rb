class AddDescriptionToNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :description, :text
  end
end
