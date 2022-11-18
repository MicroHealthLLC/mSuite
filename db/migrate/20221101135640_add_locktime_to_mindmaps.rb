class AddLocktimeToMindmaps < ActiveRecord::Migration[6.1]
  def change
    add_column :mindmaps, :failed_password_attempts, :integer
    add_column :mindmaps, :total_failed_password_attempts, :integer
    add_column :mindmaps, :lockout_period, :datetime
    add_column :mindmaps, :permanent_lock, :boolean, default: false
  end
end
