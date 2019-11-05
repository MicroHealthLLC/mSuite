class AddDescriptionToCentralIdea < ActiveRecord::Migration[5.2]
  def change
    add_column :mindmaps, :description, :text
  end
end
