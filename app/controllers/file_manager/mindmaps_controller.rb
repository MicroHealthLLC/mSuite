class FileManager::MindmapsController < AuthenticatedController
  layout "file_manager"
  before_action :set_resource, except: [:index]

  def index
    @mindmaps = Mindmap.all
  end

  def edit
  end

  private

  def set_resource
    @mindmap = Mindmap.find_by(id: params[:id])
  end
end
