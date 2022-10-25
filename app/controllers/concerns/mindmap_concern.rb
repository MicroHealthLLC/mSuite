module MindmapConcern
  extend ActiveSupport::Concern
  
  def dup_msuite
    @clone_msuite = @mindmap.deep_clone include: [:nodes, :stages, :comments,{ nodes: :children }, { comments: :replies }], use_dictionary: true
    dup_conditions()
    @clone_msuite
  end

  def check_msuite(fetched_mindmap)
    should_delete = true
    return false if fetched_mindmap.mm_type == 'pollvote'
    if fetched_mindmap.canvas
      if valid_json?(fetched_mindmap.canvas)
        canvas = JSON.parse(fetched_mindmap.canvas)
        should_delete = false if canvas['user']
      else
        should_delete = false
      end
    end
    should_delete
  end

  private

  def dup_poll()
    poll = JSON.parse(@clone_msuite.canvas)
    poll['pollData']['url'] = ''
    poll.to_json
  end

  def before_dup_calendar_todo()
      changed_month = params[:data][:month]
      changed_year = params[:data][:year]
      update_calendar_todo_dates(changed_month,changed_year)
  end
  
  def update_calendar_todo_dates(changed_month,changed_year)
    @clone_msuite.nodes.each do |node|
      node.startdate = node.startdate.change(year:changed_year, month: changed_month) if @clone_msuite.mm_type =='calendar'
      node.duedate = node.duedate.change(year:changed_year, month: changed_month) if node.duedate != nil
    end
  end

  def dup_conditions()
    before_dup_calendar_todo() if @clone_msuite.mm_type == 'todo' || @clone_msuite.mm_type == 'calendar'
    @clone_msuite.stages.skip_callback(:create, :before,:set_position) if @clone_msuite.mm_type == 'kanban'
    @clone_msuite.canvas = dup_poll() if @clone_msuite.mm_type == 'poll'
  end

  def valid_json?(string)
    !!(JSON.parse(string)) rescue false
  end
end
