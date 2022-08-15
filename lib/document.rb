require "tree.rb"
require "set"

def adjustOperation(operation1, operation2)
  if operation2["type"] != "insert"
    return operation1
  end
  return adjustInsertOperation(operation, index, priority)
end

def adjustInsertOperation(operation, index, priority)
  if operation["type"] != "insert"
    if operation["index"] < index
      return operation
    end
    return {type: operation["type"], index: (operation["index"] + 1), id: operation["id"]}
  end
  if ((operation["index"] < index) ||((operation["index"] == index) && (operation["priority"] < priority)))
    return operation
  end
  return {type: operation["type"], index: (operation["index"] + 1), id: operation["id"], priority: operation["priority"], value: operation["value"]}
end

class Document
  attr_reader :operations, :deletions, :revision
  attr_accessor :locations, :text

  def initialize
    @operations = []
    @deletions = Tree.new()
    @locations = []
    @text = ""
    @revision = 0
    @context = Set.new()
    @priority = (rand() * 0x1000000).floor()
    @counter = 0
  end

  def updates(rev)
    return @operations.slice(rev)
  end

  def operationsCount
    return @operations.length
  end

  def getId
    @counter += 1
    return (@priority * 0x1000000) + @counter
  end

  def add(operation)
    @operations.push(operation)
    case operation["type"]
    when "delete"
      if !@deletions.contains(operation["index"])
        index = @deletions.inverse(operation["index"])
        deletions.union(operation["index"])
        @text = "#{@text.slice(0, index)}#{@text.slice(index + 1)}"
        for i in (0).upto((@locations.length) - 1) do
          if @locations[i] > index
            @locations[i] -= 1
          end
        end
      end
    when "insert"
      @deletions.forwardTransform(operation["index"])
      index = @deletions.inverse(operation["index"])
      @text = "#{@text.slice(0, index)}#{operation["value"]}#{text.slice(index)}"
      for i in (0).upto((@locations.length) - 1) do
        if locations[i] > index
          locations[i] += 1
        end
      end
    end
  end

  def merge(operation, ignoreSelf = true )
    currentId = (@priority * 0x1000000) + @counter
    puts operation
    if ignoreSelf && (operation["priority"] == @priority) && (operation["id"] <= currentId)
      return
    end

    if (@revision < @operations.length) && (@operations[@revision]["id"] == id)
      while (@revision < @operations.length) && @context.include?(@operations[@revision]["id"])
        @context.delete?(@operations[@revision]["id"])
        @revision += 1
      end
      return
    end

    for index in @revision.upto((@operations.length) -1) do
      puts @operations.length
      puts @revision
      if @operations[index]["id"] == operation["id"]
        @context.add(operation["id"])
      end
    end

    insertList = []
    s = nil
    t = nil

    for index in ((@operations.length) - 1).downto(@revision) do
      current = @operations[index]
      if @current["type"]
        i = !s.nil? ? s.transform(current["index"]) : current["index"]
        if !context.include?(current["index"])
          insertList.push([(!t.nil? ? t.inverse(i) : i), current["priority"]])
          if !t.nil?
            t.union(i)
          else
            t = Tree.new(i)
          end
        end
        if !s.nil?
          s.union(i)
        else
          s = Tree.new(i)
        end
      end
    end

    for i in ((insertList.length) - 1).downto(0) do
      operation = adjustInsertOperation(operation, insertList[i][0], insertList[i][1])
    end

    isCurrent = (@revision == @operations.length)
    add(operation)
    if isCurrent
      @revision += 1
    else
      @context.add(operation["id"])
    end
  end

  def transformIndex(index)
    return @deletions.transform(index)
  end

  def self.getDiff(oldText, newText, cursor)
    delta = newText.length - oldText.length
    limit = [0, cursor - delta].max
    last = oldText.length
    while (last > limit) && (oldText[last-1] == newText[(last + delta) - 1])
      last -= 1
    end
    start = 0
    startLimit = cursor - [0, delta].max
    while (start < startLimit) && (oldText[start] == newText[start])
      start += 1
    end
    return {start: start, "end": last, newText: newText.slice(start, last + delta)}
  end

  def diffToOps(diff)
    start = diff["start"]
    last = diff["end"]
    newText = diff["newText"]
    result = []

    for i in start.upto(last - 1) do
      result.push({priority: @priority, type: "delete", index: transformIndex(i), id: getId})
    end
    index= transformIndex(last)
    for i in (0).upto(newText.length - 1) do
      result.push({priority: @priority, index: (index + 1), id: getId, value: newText[i]})
    end
    return result
  end
end