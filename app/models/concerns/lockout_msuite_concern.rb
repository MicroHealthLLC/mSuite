module LockoutMsuiteConcern
  extend ActiveSupport::Concern

  def lock_msuite
    check_msuite_lock_status
  end

  def unlock_msuite
    change_msuite_unlock
  end

  private

  def check_msuite_lock_status
    get_pwd_attempts
    check_failed_pwd
    is_permanent_lock_msuite
    update_msuite_lock_status
  end

  def get_pwd_attempts
    @p_attempts = self.failed_password_attempts
    @t_attempts = self.total_failed_password_attempts
    @setting    = Setting.first
    @s_attempts = @setting.permanent_lock
  end

  def check_failed_pwd
    @p_attempts = 1 if @p_attempts.nil?
    @t_attempts = 1 if @t_attempts.nil?
    @p_attempts = @p_attempts + 1 if @p_attempts
    @t_attempts = @t_attempts + 1 if @t_attempts
  end

  def is_permanent_lock_msuite
    @is_permanent_locked = false
    @is_permanent_locked = @t_attempts >= @s_attempts if @t_attempts
  end

  def update_msuite_lock_status
    time = Time.now
    if @is_permanent_locked
      @p_attempts = 0
      @t_attempts = 0
      time = nil
    end
    self.update({
      :failed_password_attempts => @p_attempts,
      :total_failed_password_attempts => @t_attempts,
      :permanent_lock => @is_permanent_locked,
      :lockout_period => time
    })
  end

  def change_msuite_unlock
    self.update({
      :failed_password_attempts => 0,
      :total_failed_password_attempts => 0,
      :lockout_period => nil
    })
  end
end
