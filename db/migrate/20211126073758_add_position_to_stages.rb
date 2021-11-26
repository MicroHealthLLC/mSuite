class AddPositionToStages < ActiveRecord::Migration[5.2]
  def change
    add_column :stages, :position, :integer, default: 0

    Mindmap.where(mm_type: 1).each do |mind|
      mind.stages.each_with_index do |stage, index|
        stage.update(position: index)
      end
    end
  end
end
