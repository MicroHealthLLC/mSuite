module MindmapConcern
  extend ActiveSupport::Concern
  
  def dup_msuite
    clone_msuite = @mindmap.deep_clone include: [:nodes, :stages, :comments,{ nodes: :children }, { comments: :replies }], use_dictionary: true
    clone_msuite.stages.skip_callback(:create, :before,:set_position) if @mindmap.mm_type == 'kanban'
    clone_msuite.canvas = dup_poll(clone_msuite) if clone_msuite.mm_type == 'poll'
    clone_msuite
  end

  def dup_poll(msuite)
    poll = JSON.parse(msuite.canvas)
    poll['pollData']['url'] = ''
    poll.to_json
  end

  def check_msuite(fetched_mindmap)
    should_delete = true
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

  def valid_json?(string)
    !!(JSON.parse(string)) rescue false
  end
end
