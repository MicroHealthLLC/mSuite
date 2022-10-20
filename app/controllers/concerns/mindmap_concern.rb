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
end  