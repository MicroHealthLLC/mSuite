class AddPasswordConfigureToSettings < ActiveRecord::Migration[6.1]
  def change
    add_column :settings, :failed_password_attempts, :integer
    add_column :settings, :lockout_period, :integer
    add_column :settings, :permanent_lock, :integer
  end
end
