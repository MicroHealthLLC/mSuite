class FileDeleteWorker
  include Sidekiq::Worker

  def perform
    mSuites = Mindmap.in_active_maps
    if mSuites.length > 0
      mSuites.each do |mSuite|
        if mSuite.nodes.blank? && mSuite.title == 'Title' && mSuite.canvas.canvas.nil?
          mSuite.destroy
        end
      end
    end
  end
end
