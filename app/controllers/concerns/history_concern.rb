module HistoryConcern
  extend ActiveSupport::Concern

  def undo_my_node(params)
    if params.length > 0
      if params[params.length - 1][:req] == 'deleteNode'
        request = 'deleteNode'
        myNode  = params.pop()
        if params.length > 0
          childNodes = params[params.length - 1][:node]
        end
        childCreatedNode = []
        paramNode = myNode[:node]
        if paramNode.is_a? Array
          paramNode.each do |arrayNode|
            if Node.find_by(id: arrayNode[:id]) == nil
              node_child = new_node arrayNode
              node_child.decryption.save
              childCreatedNode.push(node_child)
            end
          end
        elsif ((childNodes.is_a? Array) && (childNodes[0][:stage_id] == nil))
          node_child = new_node paramNode
          node_child.decryption.save
          childCreatedNode.push(node_child)
          childNodes.each do |arrayNode|
            if arrayNode[:id] != paramNode[:id]
              if Node.find_by(id: arrayNode[:id]) == nil
                node_child = new_node arrayNode
                node_child.decryption.save
                childCreatedNode.push(node_child)
              end
            end
          end
        elsif paramNode != nil
          my_node = new_node paramNode
          my_node.decryption.save
          createdNode = my_node
        end
        if paramNode.is_a? Array
          nodeObj = node_obj request,childCreatedNode,paramNode[0][:mindmap_id]
        elsif childCreatedNode.length > 0
          nodeObj = node_obj request,childCreatedNode,paramNode[:mindmap_id]
        elsif paramNode != nil
          nodeObj = node_obj request,createdNode,paramNode[:mindmap_id]
        end
        return nodeObj
      elsif params[params.length - 1][:req] == 'addNode'
        myNode = params.pop()
        deletedNode = nil
        if myNode[:node].is_a? Array
          deletedNode = Node.destroy(myNode[:node][0][:id])
        elsif myNode[:node]
          deletedNode = Node.destroy(myNode[:node][:id])
        end
        nodeObj = node_obj 'addNode',deletedNode,deletedNode[:mindmap_id]
        return nodeObj
      elsif params[params.length - 1][:req] == 'deleteStage'
        myStage = params.pop()
        if myStage[:stage].is_a? Array
          currentStage = myStage[:stage][0]
        else
          currentStage = myStage[:stage]
          stageNodes = myStage[:nodes]
        end
        createdStage = new_stage currentStage
        createdStage.decryption.save

        if stageNodes.is_a? Array
          childStages = []
          stageNodes.each do |arrayNode|
            if arrayNode.is_a? Array
              stageChild = arrayNode[0]
            else
              stageChild = arrayNode
            end
            child_stage = new_node stageChild
            child_stage.decryption.save
            childStages.push(child_stage)
          end
        end
        nodeObj = ({
          req: 'deleteStage',
          node: createdStage,
          childNode: childStages,
          mindmap_id: myStage[:stage][:mindmap_id]
        })
        return nodeObj
      elsif params[params.length - 1][:req] == 'addStage'
        myStage = params.pop()
        if myStage[:stage].is_a? Array
          stage = Stage.find(myStage[:stage][0][:id])
          current_mindmap_id = myStage[:stage][0][:mindmap_id]
        else
          stage = Stage.find(myStage[:stage][:id])
          current_mindmap_id = myStage[:stage][:mindmap_id]
        end
        deletedStage = stage.destroy()
        nodeObj = node_obj 'addStage',deletedStage,current_mindmap_id
        return nodeObj
      elsif params[params.length - 1][:req] == 'cutNode'
        myNode = params.pop()
        node = Node.find_by(id: myNode[:node][:id])
        current_mindmap_id = myNode[:node][:mindmap_id]
        updatedNode = node.update(is_disabled: false)
        nodeObj = node_obj 'cutNode',updatedNode,current_mindmap_id
        return nodeObj
      end
    end
  end

  def redo_my_node(params)
    if params.length > 0
      if params[params.length - 1][:req] == 'deleteNode'
        myNode = params.pop()
        deletedNodes = []
        current_mindmap_id = 0
        paramNode = nil
        if myNode[:node].is_a? Array
          myNode[:node].each do |arrayNode|
            if arrayNode.is_a? Array
              node = Node.find(arrayNode[0][:id])
              current_mindmap_id = node[:mindmap_id]
            else
              node = Node.find(arrayNode[:id])
              current_mindmap_id = node[:mindmap_id]
            end
            node.decryption
            deletedNodes.push(node.destroy())
          end
          nodeObj = node_obj 'deleteNode',deletedNodes,current_mindmap_id
          return nodeObj
        else
          paramNode = myNode[:node]
          if paramNode && Node.find(paramNode[:id]) != nil
            node = Node.find(paramNode[:id])
            deletedNode = node.destroy()
            nodeObj = node_obj 'deleteNode',deletedNode,node[:mindmap_id]
            return nodeObj
          end
        end
      elsif params[params.length - 1][:req] == 'addNode'
        myNode = params.pop()
        createdNode = new_node myNode[:node]
        createdNode.decryption.save
        nodeObj = node_obj 'addNode',createdNode,myNode[:node][:mindmap_id]
        return nodeObj
      elsif params[params.length - 1][:req] == 'deleteStage'
        myStage = params.pop()
        current_mindmap_id = 0
        if myStage[:stage].is_a? Array
          stage = Stage.find(myStage[:stage][0][:id])
          current_mindmap_id = myStage[:stage][0][:mindmap_id]
          childNodes = myStage[:nodes]
        else
          stage = Stage.find(myStage[:stage][:id])
          current_mindmap_id = myStage[:stage][:mindmap_id]
          childNodes = myStage[:nodes]
        end
        deletedStage = stage.destroy()
        nodeObj = ({
          req: 'deleteStage',
          node: deletedStage,
          childNode: childNodes,
          mindmap_id: current_mindmap_id
        })
        return nodeObj
      elsif params[params.length - 1][:req] == 'addStage'
        myStage = params.pop()
        createdStage = new_stage myStage[:stage]
        createdStage.decryption.save
        nodeObj = node_obj 'addStage',createdStage,myStage[:stage][:mindmap_id]
        return nodeObj
      else {}
      end
    end
  end

  def undo_my_mindmap(params)
    my_canvas = params.pop()
    my_canvas = params[params.length - 1]
    if (my_canvas.is_a? String) == false && my_canvas[:mindmap]
      my_canvas = my_canvas[:mindmap][:canvas]
    elsif my_canvas.is_a? String
      my_canvas
    else
      my_canvas = my_canvas.to_json
    end
    @mindmap.update(canvas: my_canvas)
  end
  def redo_my_mindmap(params)
    my_canvas = params.pop()
    @mindmap.update(canvas: my_canvas)
  end

  private

  def new_node(arrayNode)
    node = Node.new(
      id: arrayNode[:id],
      title:  arrayNode[:title],
      line_color: arrayNode[:line_color],
      mindmap_id: arrayNode[:mindmap_id],
      parent_node: arrayNode[:parent_node],
      startdate: arrayNode[:startdate],
      description: arrayNode[:description],
      position: arrayNode[:position],
      position_x: arrayNode[:position_x],
      position_y: arrayNode[:position_y],
      duedate: arrayNode[:duedate],
      is_disabled: arrayNode[:is_disabled],
      stage_id: arrayNode[:stage_id],
      element_height: arrayNode[:element_height],
      element_type: arrayNode[:element_type],
      element_width: arrayNode[:element_width]
    )
    return node
  end
  def new_stage(stage)
    stage = Stage.new(
      id: stage[:id],
      title:  stage[:title],
      stage_color: stage[:stage_color],
      mindmap_id: stage[:mindmap_id],
      position: stage[:position]
    )
    return stage
  end
  def node_obj(req,obj,m_id)
    return ({
      req: req,
      node: obj,
      mindmap_id: m_id
    })
  end
end
