class AddPositionToStages < ActiveRecord::Migration[5.2]
  def change
    add_column :stages, :position, :integer, default: 0
  end
end
