class MindmapsController < AuthenticatedController
  #before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  #before_action :set_access_user
  before_action :set_mindmap, only: [:update, :show, :destroy_file, :compute_child_nodes, :reset_mindmap]
  before_action :check_password, only:[:show]
  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea")
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json } }
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.create(mindmap_params)
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
    session[:mindmap_id]=@mindmap.id
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
    @mindmap = Mindmap.create_with(name: 'Central Idea').find_or_create_by(unique_key: params[:key])
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

  def set_access_user
    Mindmap.access_user = current_user
  end

  def set_mindmap
    @mindmap = Mindmap.find_by(unique_key: params[:id])
    #check_auth
  end

  def check_password
    if session[:mindmap_id] == @mindmap.id
      return
    elsif @mindmap.password
      if params[:password_check]
        render json:{error:"Wrong Password Entered. Kindly Enter Correct Password to Enter Mindmap"} unless @mindmap.check_password(params[:password_check])
      else
        redirect_to root_path, alert:"Sorry Kindly Provide Access Password for this Mconcept Map"
      end
    end
  end

  def check_auth
    return if current_user.try(:admin?)
    if @mindmap.only_me? && current_user.try(:id) != @mindmap.user.try(:id)
      return redirect_to root_path
    elsif @mindmap.private_link? && !@mindmap.shared_users.include?(current_user)
      return redirect_to root_path
    end
  end

  def mindmap_params
    params.require(:mindmap).permit(
      :name,
      :mm_type,
      :description,
      :password,
      node_files: []
    )
  end

  def file_params
    params.require(:file).permit(:id, :uri)
  end
end
