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
      respond_to do |format|
        format.json { render json: {stage: @stage} }
        format.html { }
      end
    end
  end

  def update
   if @stage.update(stage_params)
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
      :mindmap_id
    )
  end
end