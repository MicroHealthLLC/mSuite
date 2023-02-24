require 'json'
class MindmapsController < AuthenticatedController
  include HistoryConcern, MindmapConcern
  #before_action :authenticate_user!, except: [:index, :show, :compute_child_nodes]
  #before_action :set_access_user
  before_action :set_mindmap, only: [:update, :show, :compute_child_nodes, :reset_mindmap, :destroy, :clone_map, :undo_mindmap, :redo_mindmap]
  before_action :verify_password, only: :show
  prepend_before_action :check_password_update, only: :update

  def index; end

  def new
    @mindmap = Mindmap.new(name: "Central Idea")
    respond_to do |format|
      format.json { render render_mindmap(@mindmap,nil)}
      format.html { render action: 'index' }
    end
  end

  def create
    @mindmap = Mindmap.new(mindmap_params)
    if @mindmap.save
      render json: render_mindmap(@mindmap,nil) 
    else
      render json: { mindmap: @mindmap.to_json, messages: @mindmap.errors.full_messages, errors: @mindmap.errors.to_json }, status: :found
    end
  end

  def update
    if @mindmap.update(mindmap_params)
      @mindmap = @mindmap.decrypt_attributes
      @mindmap.password_check
      broadcast_actioncable(@mindmap,password_present?)
      render json: render_mindmap(@mindmap,nil)
    end
  end

  def show
    if @mindmap
      respond_to do |format|
        format.json { render json: render_mindmap(@mindmap,nil)}
        format.html { render action: 'index' }
      end
    else
      respond_to do |format|
        format.json { render json: { error: 'The file you were working on was deleted by a user.' } }
        format.html { redirect_to error_404_path }
      end
    end
  end

  def find_or_create
    @mindmap = Mindmap.create_with(name: 'Central Idea').find_or_create_by(unique_key: params[:key])
    respond_to do |format|
      format.json { render json: render_mindmap(@mindmap,true) }
      format.html {}
    end
  end

  def list_all_maps
    @mindmaps = Mindmap.order('updated_at DESC')
    respond_to do |format|
      format.json { render json: render_mindmap(@mindmap,true) }
      format.html {}
    end
  end

  def reset_mindmap
    @mindmap.reset_mindmap
    @mindmap = @mindmap.decrypt_attributes
    broadcast_actioncable(@mindmap,'Reset mindmap')
    render json: { success: true, mindmap: @mindmap }
  end

  def undo_mindmap
    undoNode = params[:undoNode] if params[:undoNode]
    undo_mindmap = params[:undoCanvas] if params[:undoCanvas]
    if undoNode
      myNode = undo_my_node(undoNode)
      if myNode
        ActionCable.server.broadcast( "web_notifications_channel#{myNode[:mindmap_id]}", {message: "undo mindmap", node: myNode} )
        render json: { success: true, undoObj: myNode }
      end
    else
      myMindmap = undo_my_mindmap(undo_mindmap)
      broadcast_actioncable(@mindmap,'Mindmap Updated')
      render json: { success: true, canvas: @mindmap.canvas }
    end
  end

  def redo_mindmap
    redoNode = params[:redoNode] if params[:redoNode]
    redo_mindmap = params[:redoCanvas] if params[:redoCanvas]
    if redoNode
      myNode = redo_my_node(redoNode)
      if myNode
        ActionCable.server.broadcast( "web_notifications_channel#{myNode[:mindmap_id]}", { message: "redo mindmap", node: myNode} )
        render json: { success: true, redoObj: myNode }
      end
    else
      myMindmap = redo_my_mindmap(redo_mindmap)
      broadcast_actioncable(@mindmap,'Mindmap Updated')
      render json: { success: true, canvas: @mindmap.canvas }
    end
  end

  def destroy
    if check_for_password && @mindmap.destroy
      ActionCable.server.broadcast("web_notifications_channel#{@mindmap.id}", {message: 'Mindmap Deleted', mindmap: @mindmap})
      respond_to do |format|
        format.json { render json: { success: true } }
        format.html {}
      end
    else
      respond_to do |format|
        format.json { render json: { success: false } }
        format.html {}
      end
    end
  end

  def compute_child_nodes
    respond_to do |format|
      format.json { render json: { success: true, mindmap: @mindmap.compute_child } }
      format.html {}
    end
  end

  def delete_empty_msuite
    fetched_mindmap = Mindmap.find_by(unique_key: params[:unique_key])
    fetched_mindmap = fetched_mindmap.decrypt_attributes if fetched_mindmap
    if check_msuite(fetched_mindmap)
      if fetched_mindmap.destroy
        ActionCable.server.broadcast("web_notifications_channel#{fetched_mindmap.id}", {message: 'Mindmap Deleted', mindmap: fetched_mindmap})
      end
    end
  end

  def clone_map
    msuite_clone = dup_msuite
    if msuite_clone.save
      set_callbacks_after_dup(msuite_clone)
      render json: render_mindmap(msuite_clone,nil)
    else
      render json: { mindmap: msuite_clone.to_json, messages: msuite_clone.errors.full_messages, errors: msuite_clone.errors.to_json }, status: :found
    end
  end

  def sendkeys; end

  private

    def set_callbacks_after_dup(msuite_clone)
      if @mindmap.mm_type == 'kanban'
        msuite_clone.stages.set_callback(:create, :before,:set_position) 
        msuite_clone.stages.set_callback(:create, :before,:encrypt_attributes) 
      end
      Mindmap.set_callback(:create, :before,:update_canvas)
      Node.set_callback(:create, :before,:encrypt_attributes)
    end

    def set_access_user
      Mindmap.access_user = current_user
    end

    def password_present?
      message = "Mindmap Updated"
      if params[:mindmap][:password].present? && params[:old_password]
        message              = "Password Updated"
        session[:mindmap_id] = @mindmap.unique_key + @mindmap.password
      end
      return message
    end

    def set_mindmap
      @mindmap = Mindmap.find_by(unique_key: params[:id])
      updateMindmap if @mindmap
    end

    def updateMindmap
      in_active_days = @mindmap.will_delete_at.mjd - @mindmap.updated_at.to_date.mjd
      @mindmap.update(will_delete_at: in_active_days.days.from_now)
    end

    def verify_password
      @is_verified = true
      if @mindmap && @mindmap.password.present?
        check_status = @mindmap.check_validate(session[:mindmap_id], params[:password_check])
        @is_verified = check_status[0]
        session[:mindmap_id] = check_status[1] if @is_verified
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
      if params[:mindmap][:nodes]
        nodes = params[:mindmap].delete(:nodes) 
        params[:mindmap][:nodes_attributes] = nodes
      end
      params.require(:mindmap).permit(
        :name,
        :mm_type,
        :description,
        :password,
        :line_color,
        :image,
        :canvas,
        :title,
        :is_save,
        :parent_id,
        :will_delete_at,
        :failed_password_attempts,
        nodes_attributes: [:id, :title, :position_x, :position_y, :parent_node, :mindmap_id, :is_disabled, :hide_children , :hide_self, :line_color, :description, :export_index, :stage_id, :position, :node_width, :duedate, :startdate]
      )
    end

    def check_password_update
      if params[:mindmap][:password].present? && params[:old_password]
        @mindmap = Mindmap.find_by(unique_key: params[:id])
        unless @mindmap.password.present? && @mindmap.check_password(params[:old_password]) || @mindmap.password.blank?
          render json: { error: "Password Mismatched" }
        else
          session.delete(:mindmap_id)
        end
      end
    end

  def render_mindmap(msuite,success)
    json = {mindmap: msuite.to_json, deleteAfter: ENV['DELETE_AFTER'].to_i,defaultDeleteDays: ENV['MAX_EXP_DAYS'].to_i,expDays: ENV['EXP_DAYS'].to_i }
    json['is_verified'] = @is_verified unless @is_verified.nil? 
    json['success'] = true unless success.nil? 
    json
  end
end
