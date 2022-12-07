module HistoryConcern
  extend ActiveSupport::Concern

  def undo_my_node(params)
    if params.length > 0
      if params[params.length - 1][:req] == 'deleteNode'
        myNode = params.pop()
        if params.length > 0
          if params[params.length - 1][:receivedNodes]
            childNodes = params[params.length - 1][:receivedNodes]
          else
            childNodes = params[params.length - 1][:node]
          end
        end
        childCreatedNode = []
        paramNode = nil
        if myNode[:node]
          paramNode = myNode[:node]
        else
          paramNode = myNode[:receivedData]
        end
        if paramNode.is_a? Array
          paramNode.each do |arrayNode|
            if Node.find_by(id: arrayNode[:id]) == nil
              if ((arrayNode[:is_disabled]) || (arrayNode[:duedate]))
                duedate = arrayNode[:duedate]
                is_disabled = arrayNode[:is_disabled]
              else
                duedate = ''
                is_disabled = false
              end
              if arrayNode[:stage_id]
                stageID = arrayNode[:stage_id]
              else
                stageID = nil
              end
              childCreatedNode.push(Node.create([
                id: arrayNode[:id],
                title:  arrayNode[:title],
                line_color: arrayNode[:line_color],
                mindmap_id: arrayNode[:mindmap_id],
                parent_node: arrayNode[:parent_node],
                startdate: arrayNode[:startdate],
                description: arrayNode[:description],
                position_x: arrayNode[:position_x],
                position_y: arrayNode[:position_y],
                duedate: duedate,
                is_disabled: is_disabled,
                stage_id: stageID
              ]))
            end
          end
        elsif ((childNodes.is_a? Array) && (childNodes[0][:stage_id] == nil))
          if ((paramNode[:is_disabled]) || (paramNode[:duedate]))
            duedate = paramNode[:duedate]
            is_disabled = paramNode[:is_disabled]
          else
            duedate = ''
            is_disabled = false
          end
          childCreatedNode.push(Node.create([
            id: paramNode[:id],
            title:  paramNode[:title],
            line_color: paramNode[:line_color],
            mindmap_id: paramNode[:mindmap_id],
            parent_node: paramNode[:parent_node],
            position_x: paramNode[:position_x],
            position_y: paramNode[:position_y],
            duedate: duedate,
            is_disabled: is_disabled
          ]))
          childNodes.each do |arrayNode|
            if arrayNode[:id] != paramNode[:id]
              if Node.find_by(id: arrayNode[:id]) == nil
                if ((arrayNode[:duedate]) || (arrayNode[:is_disabled]))
                  duedate = arrayNode[:duedate]
                  is_disabled = arrayNode[:is_disabled]
                else
                  duedate = ''
                  is_disabled = false
                end
                if paramNode[:stage_id]
                  stageID = paramNode[:stage_id]
                else
                  stageID = nil
                end
                node_child = Node.new(
                  id: arrayNode[:id],
                  title:  arrayNode[:title],
                  line_color: arrayNode[:line_color],
                  mindmap_id: arrayNode[:mindmap_id],
                  parent_node: arrayNode[:parent_node],
                  position_x: arrayNode[:position_x],
                  position_y: arrayNode[:position_y],
                  duedate: duedate,
                  is_disabled: is_disabled,
                  stage_id: stageID
                )
                node_child.decryption.save
                childCreatedNode.push(node_child)
              end
            end
          end
        elsif paramNode != nil
          if paramNode[:is_disabled]
            duedate = paramNode[:duedate]
            is_disabled = paramNode[:is_disabled]
          else
            duedate = nil
            is_disabled = false
          end
          if paramNode[:stage_id]
            stageID = paramNode[:stage_id]
          else
            stageID = nil
          end
          if paramNode[:startdate]
            duedate = paramNode[:duedate]
          end
          createdNode = Node.create([
            id: paramNode[:id],
            title:  paramNode[:title],
            line_color: paramNode[:line_color],
            mindmap_id: paramNode[:mindmap_id],
            parent_node: paramNode[:parent_node],
            startdate: paramNode[:startdate],
            description: paramNode[:description],
            position_x: paramNode[:position_x],
            position_y: paramNode[:position_y],
            duedate: duedate,
            stage_id: stageID,
            is_disabled: is_disabled
            ])
        end
        if paramNode.is_a? Array
          nodeObj = ({
            req: 'deleteNode',
            node: childCreatedNode,
            mindmap_id: paramNode[0][:mindmap_id]
          })
        elsif childCreatedNode.length > 0
          nodeObj = ({
            req: 'deleteNode',
            node: childCreatedNode,
            mindmap_id: paramNode[:mindmap_id]
            })
        elsif paramNode != nil
          nodeObj = ({
            req: 'deleteNode',
            node: createdNode,
            mindmap_id: paramNode[:mindmap_id]
          })
        end
        return nodeObj
      elsif params[params.length - 1][:req] == 'addNode'
        myNode = params.pop()
        if myNode[:receivedData].is_a? Array
          checkNode = Node.find(myNode[:receivedData][0][:id])
        elsif myNode[:receivedData]
          checkNode = Node.find(myNode[:receivedData][:id])
        else
          checkNode = Node.find(myNode[:node][0][:id])
        end
        if checkNode != nil
          deletedNode = checkNode.destroy()
          nodeObj = ({
            req: 'addNode',
            node: deletedNode,
            mindmap_id: checkNode[:mindmap_id]
          })
          return nodeObj
        end
      elsif params[params.length - 1][:req] == 'deleteStage'
        myStage = params.pop()
        if myStage[:stage].is_a? Array
          currentStage = myStage[:stage][0]
        else
          currentStage = myStage[:stage]
          stageNodes = myStage[:nodes]
        end
        createdStage = Stage.create([
          id: currentStage[:id],
          title:  currentStage[:title],
          stage_color: currentStage[:stage_color],
          mindmap_id: currentStage[:mindmap_id],
          position: currentStage[:position]
        ])
        if stageNodes.is_a? Array
          childStages = []
          stageNodes.each do |arrayNode|
            if arrayNode.is_a? Array
              stageChild = arrayNode[0]
            else
              stageChild = arrayNode
            end
            childStages.push(Node.create([
              id: stageChild[:id],
              title:  stageChild[:title],
              line_color: stageChild[:line_color],
              mindmap_id: stageChild[:mindmap_id],
              parent_node: stageChild[:parent_node],
              stage_id: stageChild[:stage_id]
            ]))
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
        nodeObj = ({
          req: 'addStage',
          node: deletedStage,
          mindmap_id: current_mindmap_id
        })
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
          nodeObj = ({
            req: 'deleteNode',
            node: deletedNodes,
            mindmap_id: current_mindmap_id
          })
          return nodeObj
        else
          paramNode = myNode[:node]
          if paramNode && Node.find(paramNode[:id]) != nil
            node = Node.find(paramNode[:id])
            deletedNode = node.destroy()
            nodeObj = ({
              req: 'deleteNode',
              node: deletedNode,
              mindmap_id: node[:mindmap_id]
            })
            return nodeObj
          end
        end
      elsif params[params.length - 1][:req] == 'addNode'
        myNode = params.pop()
        if ((myNode[:node][:is_disabled]) || (myNode[:node][:duedate]))
          duedate = myNode[:node][:duedate]
          is_disabled = myNode[:node][:is_disabled]
        else
          duedate = nil
          is_disabled = false
        end
        if myNode[:node][:stage_id]
          stageID = myNode[:node][:stage_id]
        else
          stageID = nil
        end
        createdNode = Node.new(
          id: myNode[:node][:id],
          title:  myNode[:node][:title],
          line_color: myNode[:node][:line_color],
          mindmap_id: myNode[:node][:mindmap_id],
          parent_node: myNode[:node][:parent_node],
          startdate: myNode[:node][:startdate],
          description: myNode[:node][:description],
          position_x: myNode[:node][:position_x],
          position_y: myNode[:node][:position_y],
          stage_id: stageID,
          duedate: duedate,
          is_disabled: is_disabled
        )
        createdNode.decryption.save
        nodeObj = ({
          req: 'addNode',
          node: createdNode,
          mindmap_id: myNode[:node][:mindmap_id]
        })
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
        createdStage = Stage.create([
          id: myStage[:stage][:id],
          title:  myStage[:stage][:title],
          stage_color: myStage[:stage][:stage_color],
          mindmap_id: myStage[:stage][:mindmap_id],
          position: myStage[:stage][:position]
        ])
        nodeObj = ({
          req: 'addStage',
          node: createdStage,
          mindmap_id: myStage[:stage][:mindmap_id]
        })
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
end
