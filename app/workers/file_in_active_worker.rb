class FileInActiveWorker
  include Sidekiq::Worker

  def perform
    mSuites = Mindmap.where("will_delete_at <= ?", Date.today)
    if mSuites.length > 0
      mSuites.each do |mSuite|
        mSuite.destroy
      end
    end
  end
end
