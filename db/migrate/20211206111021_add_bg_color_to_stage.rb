class AddBgColorToStage < ActiveRecord::Migration[5.2]
  def change
   add_column :stages, :stage_color, :string, default: "#ebecf0"
  end
end
