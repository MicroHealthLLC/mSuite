class MindmapsController < AuthenticatedController
  #before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  #before_action :set_access_user
  before_action :set_mindmap, only: [:update, :show, :destroy_file, :compute_child_nodes, :reset_mindmap, :destroy]
  before_action :verify_password, only: :show
  before_action :check_password_update, only: :update
  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea")
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json } }
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.new(mindmap_params)
    if @mindmap.save
      render json: { mindmap: @mindmap.to_json }
    else
      render json: { mindmap: @mindmap.to_json, messages: @mindmap.errors.full_messages, errors: @mindmap.errors.to_json }, status: 422
    end
  end

  def update
    @mindmap.update(mindmap_params)
    message = params[:mindmap][:password].present? ? "Password Updated" : "Mindmap Updated"
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: message, mindmap: @mindmap
    respond_to do |format|
      format.json { render json: {mindmap: @mindmap.to_json}}
      format.html { }
    end
  end

  def show
    respond_to do |format|
      format.json { render json: { mindmap: @mindmap.to_json, is_verified: @is_verified } }
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

  def destroy
    if check_for_password && @mindmap.destroy
      ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "Mindmap Deleted", mindmap: @mindmap
      respond_to do |format|
        format.json { render json: {success: true}}
        format.html { }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false}}
        format.html { }
      end
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
  end

  def verify_password
    @is_verified = true
    if @mindmap.password.present? && session[:mindmap_id] == @mindmap.unique_key + @mindmap.password
      return
    elsif @mindmap.password.present?
      if params[:password_check].present?
        @is_verified = @mindmap.check_password(params[:password_check])
        session[:mindmap_id] = @mindmap.unique_key + @mindmap.password if @is_verified
      else
        @is_verified = false
      end
    end
  end

  def check_for_password
    verfied_delete = false
    if @mindmap.password.blank?
      verfied_delete = true
    elsif params[:password_check] && @mindmap.password.present?
      verfied_delete = @mindmap.check_password(params[:password_check])
    end
    verfied_delete
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
      :line_color,
      :image,
      :title,
      node_files: []
    )
  end

  def file_params
    params.require(:file).permit(:id, :uri)
  end

  def check_password_update
    if params[:mindmap][:password].present?
      unless @mindmap.password.present? && @mindmap.check_password(params[:mindmap][:old_password]) || @mindmap.password.blank?
        respond_to do |format|
          format.json { render json: {error: "Password Mismatched"}}
        end
      else
        session.delete(:mindmap_id)
      end
    end
  end
end
