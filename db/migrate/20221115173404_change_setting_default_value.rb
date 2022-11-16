class ChangeSettingDefaultValue < ActiveRecord::Migration[6.1]
  def change
    # Failed Password Attempts
    change_column_default(:settings,:failed_password_attempts,from: nil,to: 0)
    # Lockout Period (mins only)
    change_column_default(:settings,:lockout_period,from: nil,to: 1)
    # Permanent Lock File after Attempts
    change_column_default(:settings,:permanent_lock,from: nil,to: 5)

    Setting.where(failed_password_attempts: nil).update_all(failed_password_attempts: 0)
    Setting.where(lockout_period: nil).update_all(lockout_period: 1)
    Setting.where(permanent_lock: nil).update_all(permanent_lock: 5)

    change_column_null(:settings, :failed_password_attempts, false)
    change_column_null(:settings, :lockout_period, false)
    change_column_null(:settings, :permanent_lock, false)

  end
end
