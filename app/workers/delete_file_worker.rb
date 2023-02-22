class DeleteFileWorker
  include Sidekiq::Worker

  def perform
    mSuites = Mindmap.fileshare_created_before(1.hour.ago)
    if mSuites.length > 0
      mSuites.each do |mSuite|
        mSuite.destroy
        ActionCable.server.broadcast( "web_notifications_channel#{mSuite['id']}", {message: "Mindmap Deleted", mindmap: mSuite} )
      end
    end
  end
end
