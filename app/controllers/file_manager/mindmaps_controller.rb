class FileManager::MindmapsController < AuthenticatedController
  layout "file_manager"
  before_action :authenticate_user!
  before_action :require_admin
  before_action :set_resource, except: [:index]

  def index
    @mindmaps = Mindmap.all
    @shared_mindmaps = Mindmap.joins(:mindmap_users).where("mindmap_users.user_id = ?", current_user.id)
    @shared_mindmaps = @shared_mindmaps.where.not(share: :only_me, user_id: current_user.id)
  end

  def edit
  end

  def update
    if @mindmap.update!(mindmap_params)
      flash[:success] = "Successfully updated!"
      redirect_to file_manager_path
    else
      flash[:alert] = "Record Not update!"
      render :new
    end
  end

  private

  def set_resource
    @mindmap = Mindmap.find_by(id: params[:id])
    check_auth
  end

  def check_auth
    return if current_user.try(:admin?) || @mindmap.user_id == current_user.id
    redirect_to file_manager_path
  end

  def mindmap_params
    params.require(:mindmap).permit(
      :name,
      :status,
      :share,
      :category_id,
      :description,
      shared_user_ids: []
    )
  end
end
