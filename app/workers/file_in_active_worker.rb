class FileInActiveWorker
  include Sidekiq::Worker

  def perform
    mSuites = Mindmap.where(will_delete_at: DateTime.now.to_date)
    if mSuites.length > 0
    	mSuites.each do |mSuite|
    		mSuite.delete
    	end
    end
  end
end