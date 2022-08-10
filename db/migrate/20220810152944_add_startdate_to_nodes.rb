class AddStartdateToNodes < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :startdate, :datetime
  end
end
