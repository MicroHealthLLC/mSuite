class AddIsSaveToMindmaps < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :is_save, :integer
  end
end
