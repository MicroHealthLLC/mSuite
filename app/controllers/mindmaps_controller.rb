class MindmapsController < AuthenticatedController
  before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  before_action :set_mindmap, only: [:update, :show, :destroy_file, :compute_child_nodes, :reset_mindmap]

  def index; end

  def new
    @mindmap = current_user.mindmaps.new(name: "Central Idea")
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json } }
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = current_user.mindmaps.create(mindmap_params)
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json } }
      format.html { }
    end
  end

  def update
    @mindmap.update(mindmap_params)
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "This is Message"
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json } }
      format.html { render action: 'index' }
    end
  end

  def destroy_nodes
    nodes = params[:nodes]
    nodes.each do |nod|
      Node.find(nod[:id]).destroy
    end if nodes.present?
    respond_to do |format|
      format.json { render json: {success: true}}
      format.html { }
    end
  end

  def find_or_create
    @mindmap = current_user.mindmaps.create_with(name: 'Central Idea').find_or_create_by(unique_key: params[:key])
    respond_to do |format|
      format.json { render json: {success: true, mindmap: @mindmap}}
      format.html { }
    end
  end

  def list_all_maps
    @mindmaps = Mindmap.order('updated_at DESC')
    respond_to do |format|
      format.json { render json: {success: true, mindmaps: @mindmaps}}
      format.html { }
    end
  end

  def destroy_file
    if file = @mindmap.node_files.find_by(id: file_params[:id]) and file.present?
      file.purge
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", {message: "Central Node file deleted", file: file}
      respond_to do |format|
        format.json {render json: {success: true}}
        format.html {}
      end
    else
      respond_to do |format|
        format.json {render json: {success: false}}
        format.html {}
      end
    end
  end

  def reset_mindmap
    @mindmap.reset_mindmap
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", {message: "Reset mindmap"}
    respond_to do |format|
      format.json {render json: {success: true}}
      format.html {}
    end
  end

  def compute_child_nodes
    respond_to do |format|
      format.json { render json: {success: true, mindmap: @mindmap.compute_child}}
      format.html { }
    end
  end

  private

  def set_mindmap
    # Mindmap.user_id = current_user.try(:id)
    @mindmap = Mindmap.find_by(unique_key: params[:id])
  end

  def mindmap_params
    params.require(:mindmap).permit(
      :name,
      :description,
      node_files: []
    )
  end

  def file_params
    params.require(:file).permit(:id, :uri)
  end
end
