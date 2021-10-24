class AddStatusInNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :status, :string
  end
end
