class AddDueDateInTodos < ActiveRecord::Migration[5.2]
  def change
    add_column :nodes, :duedate, :datetime
  end
end
