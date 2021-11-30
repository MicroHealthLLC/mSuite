class StagesController < AuthenticatedController
  before_action :set_stage, only: [:update,:destroy]

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
   if @stage.update(stage_params)
    ActionCable.server.broadcast "web_notifications_channel#{@stage.mindmap.id}", message: "Stage Updated", stage: @stage
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
    if @stage.destroy
      ActionCable.server.broadcast "web_notifications_channel#{@stage.mindmap.id}", message: "Stage Deleted", stage: @stage
      respond_to do |format|
        format.json { render json: {success: true} }
        format.html { }
      end
    else
      respond_to do |format|
        format.json { render json: {success: false} }
        format.html { }
      end
    end
  end

  private

  def set_stage
    @stage = Stage.find_by(id: params[:id])
  end

  def stage_params
    params.require(:stage).permit(
      :title,
      :mindmap_id,
      :position
    )
  end
end
