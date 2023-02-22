module MindmapConcern
  extend ActiveSupport::Concern
  
  def dup_msuite
    @clone_msuite = @mindmap.deep_clone include: [:nodes, :stages, :comments,{ nodes: :children }, { comments: :replies }], use_dictionary: true
    dup_conditions()
    @clone_msuite
  end

  def check_msuite(fetched_mindmap)
    should_delete = true
    return false if !fetched_mindmap || fetched_mindmap.mm_type == 'pollvote'
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

  def broadcast_actioncable(mindmap,message)
    ActionCable.server.broadcast("web_notifications_channel#{mindmap.id}", {message: message, mindmap: mindmap.to_json})
  end
  
  private

    def dup_poll(canvas)
      canvas = EncryptionService.decrypt(canvas) if @clone_msuite.is_private?
      poll = JSON.parse(canvas)
      poll['pollData']['url'] = ''
      for data in poll['pollData']['Questions']
        data['voters'] = []
        for voters in data['answerField']
          voters['votes'] = []
        end
      end
      poll = poll.to_json
      poll = EncryptionService.encrypt(poll) if @clone_msuite.is_private?
      poll
    end

    def before_dup_calendar_todo()
        changed_month = params[:data][:month]
        changed_year = params[:data][:year]
        update_calendar_todo_dates(changed_month,changed_year)
    end
    
    def update_calendar_todo_dates(changed_month,changed_year)
      @clone_msuite.nodes.each do |node|
        node.startdate = node.startdate.change(year:changed_year, month: changed_month)
        node.duedate = node.duedate.change(year:changed_year, month: changed_month) if node.duedate != nil
      end
    end

    def dup_conditions()
      before_dup_calendar_todo() if @clone_msuite.mm_type == 'todo' || @clone_msuite.mm_type == 'calendar'
      skip_callbacks_on_dup
      @clone_msuite.canvas = dup_poll(@clone_msuite.canvas) if @clone_msuite.mm_type == 'poll'
    end

    def valid_json?(string)
      !!(JSON.parse(string)) rescue false
    end

    def skip_callbacks_on_dup
      if @clone_msuite.mm_type == 'kanban'
        @clone_msuite.stages.skip_callback(:create, :before,:set_position) 
        @clone_msuite.stages.skip_callback(:create, :before,:encrypt_attributes)
      end
      Mindmap.skip_callback(:create, :before,:update_canvas)
      Node.skip_callback(:create, :before,:encrypt_attributes)
    end
end
