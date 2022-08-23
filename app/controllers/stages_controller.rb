class StagesController < AuthenticatedController
  before_action :set_stage, only: [:update,:destroy]
  before_action :set_mindmap, only: [:reset_stages]

  def create
    @stage = Stage.create(stage_params)
    if @stage.new_record?
      respond_to do |format|
        format.json { render json: {status: 500} }
        format.html { }
      end
    else
      ActionCable.server.broadcast "web_notifications_channel#{@stage.mindmap.id}", message: "Stage Created", stage: @stage
      respond_to do |format|
        format.json { render json: {stage: @stage} }
        format.html { }
      end
    end
  end

  def update
    @stages = Stage.where(mindmap_id: @stage.mindmap_id)
    if @stage.update(stage_params)
      ActionCable.server.broadcast "web_notifications_channel#{@stage.mindmap.id}", message: "Stage Updated", stage: @stage, stages: @stages
      respond_to do |format|
        format.json { render json: {stage: @stage} }
        format.html { }
      end
    end
  end

  def index
    @stages = Stage.where(mindmap_id: params[:mindmap_id])
    respond_to do |format|
      format.json { render json: {stages: @stages} }
      format.html { }
    end
  end

  def destroy
    stageNodes = @stage.nodes.to_json
    if @stage.destroy
      stageNodes = JSON.parse(stageNodes)
      ActionCable.server.broadcast "web_notifications_channel#{@stage.mindmap.id}", message: "Stage Deleted", stage: @stage
      respond_to do |format|
        format.json { render json: {success: true, stage: @stage, nodes: stageNodes} }
        format.html { }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false} }
        format.html { }
      end
    end
  end

  def reset_stages
    Stage.where(mindmap_id: params[:mindmap_id]).delete_all
    @mindmap.stages.create([{title:'TO DO'},{title:'IN PROGRESS'},{title:'DONE'}])
    @stages = Stage.where(mindmap_id: params[:mindmap_id])
    ActionCable.server.broadcast "web_notifications_channel#{@mindmap.id}", message: "Stage Reset", stages: @stages
    respond_to do |format|
      format.json { render json: {stages: @stages} }
      format.html { }
    end
  end

  private

  def set_stage
    @stage = Stage.find_by(id: params[:id])
  end

  def set_mindmap
    @mindmap = Mindmap.find_by_id(params[:mindmap_id])
  end

  def stage_params
    params.require(:stage).permit(
      :title,
      :mindmap_id,
      :position,
      :stage_color
    )
  end
end
