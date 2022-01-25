class AddInActiveToMindmap < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :will_delete_at, :date
  end
end
