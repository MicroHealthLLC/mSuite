class TreeNode
  attr_reader :value, :left, :right, :height, :size

  def initialize(value, left = nil, right = nil)
    leftHeight = !left.nil? ? left.height: 0
    rightHeight = !right.nil? ? right.height : 0
    if leftHeight > rightHeight + 1
      @value = left.value
      @left = left.left
      @right = TreeNode.new(value - left.value, left.right, right)
    elsif rightHeight > leftHeight + 1
      @left = TreeNode.new(value, left, right.left)
      @value = value + right.value
      @right = right.right
    else
      @left = left
      @right = right
      @value = value
    end
    @size = (!@left.nil? ? @left.size : 0) + ( !@right.nil? ? @right.size : 0) + 1
    @height = [(!@left.nil? ? @left.height : 0), (!@right.nil? ? @right.height : 0)].max
  end
end

class Tree
  def initialize(value = nil)
    if (!value.nil?)
      @root = TreeNode.new(value)
    else
      @root = nil
    end
  end
  def height
    return !@root.nil? ? @root.height : 0
  end

  def size
    return !@root.nil? ? @root.height : 0
  end

  def forwardTransform(i, node = nil)
    if node.nil?
      if !@root.nil?
        @root = forwardTransform(i, @root)
        return @root
      else
        return nil
      end
    end
    if i <= node.value
      transformLeft = !node.left.nil? ? forwardTransform(i, node.left) : node.left
      return TreeNode.new(node.value + 1, transformLeft, node.right)
    else
      transformRight = !node.right.nil? ? forwardTransform(i - node.value, node.right) : node.right
      return TreeNode.new(node.value, node.left, transformRight)
    end
  end

  def inverse(i)
    node = @root
    result = i
    while !node.nil?
      if i < node.value
        node = node.left
      else
        i -= node.value
        result -= (!node.left.nil? ? node.left.size : 0) + 1
        node = node.right
      end
    end
    return result
  end

  def transform(i)
    node = @root
    base = 0
    while !node.nil?
      left = node.left
      x = node.value - (!left.nil? ? left.size : 0)
      if i < x
        node = left
      else
        i = 1 + i - x
        base += node.value
        node = node.right
      end
    end
    base + i
  end

  def union(i, node = nil)
    if node.nil?
      if !@root.nil?
        @root = union(i, @root)
        return @root
      else
        @root = TreeNode.new(i)
        return @root
      end
    end
    if i < node.value
      unionLeft = !node.left.nil? ? union(i, node.left) : TreeNode.new(i)
      return TreeNode.new(node.value, unionLeft, node.right)
    elsif i > node.value
      unionRight = !node.right.nil? ? union(i - node.value, node.right) : TreeNode.new(i - node.value)
      return TreeNode.new(node.value, node.left, unionRight)
    else
      return node
    end
  end

  def contains(i)
    node = @root
    while !node.nil?
      if i < node.value
        node = node.left
      elsif i > node.value
        i -= node.value
        node = node.right
      else
        return true
      end
    end
    return false
  end

  def toArray (node= nil, base = nil, result = nil)
    node = !node.nil? ? node : @root
    base = !base.nil? ? base : 0
    result = !result.nil? ? result : []
    if !node.nil?
      if !node.left.nil?
        toArray(node.left, base, result)
      end
      base += node.value
      result.push(base)
      if !node.right.nil?
        toArray(node.right, base, result)
      end
    end
    return result
  end
end

if __FILE__ == $0
  tree = Tree.new(7)
  tree.union(2)
  tree.union(0)
  p tree.toArray()


  tree.union(2)
  tree.union(3)
  p tree.toArray()

  #tree.union(200)
  #p tree.toArray()
  for i in (200).downto(101) do
    tree.union(i)
  end

  p tree.toArray()

  for i in (0).upto(9) do
    puts "#{i} #{tree.transform(i)} #{tree.inverse(tree.transform(i))} #{tree.contains(i)}"
  end
end