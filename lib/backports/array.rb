class Array
  # Standard in Ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  class << self
    # Try to convert obj into an array, using to_ary method.
    # Returns converted array or nil if obj cannot be converted
    # for any reason. This method is to check if an argument is an array.
    def try_convert(obj)
      return nil unless obj.respond_to?(:to_ary)
      Type.coerce_to(obj, Array, :to_ary)
    end
  end


  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def combination(num)
    num = Type.coerce_to num, Fixnum, :to_int
    return to_enum(:combination, num) unless block_given?
    return self unless (0..size).include? num
    # Implementation note: slightly tricky.
                                             # Example: self = 1..7, num = 3
    picks = (0...num).to_a                   # picks start at 0, 1, 2
    max = ((size-num)...size).to_a           # max (index for a given pick) is [4, 5, 6]
    pick_max_pairs = picks.zip(max).reverse  # pick_max_pairs = [[2, 6], [1, 5], [0, 4]]
    lookup = pick_max_pairs.find(Proc.new{return self})
    loop do
      yield values_at(*picks)
      move = lookup.each{|pick, max| picks[pick] < max}.first
      new_index = picks[move] + 1
      picks[move...num] = (new_index...(new_index+num-move)).to_a
    end
  end unless method_defined? :combination

  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def cycle(n = nil, &block)
    return to_enum(:cycle, n) unless block_given?
    if n.nil?
      loop(&block)
    else
      n = Type.coerce_to n, Fixnum, :to_int
      n.times{each(&block)}
    end
    nil
  end unless method_defined? :cycle

  # Standard in rails, and we use it here...
  def extract_options!
    last.is_a?(::Hash) ? pop : {}
  end unless method_defined? :extract_options!

  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  make_block_optional :collect!, :map!, :each, :each_index, :reverse_each, :reject, :reject!, :delete_if, :test_on => [42]

  # flatten & flatten!, standard in ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  unless ([[]].flatten(1) rescue false)

    # Recursively flatten any contained Arrays into an one-dimensional result.
    # Adapted from rubinius'
    def flatten_with_optional_argument(level=-1)
      dup.flatten!(level) || self
    end

    # Flattens self in place as #flatten. If no changes are
    # made, returns nil, otherwise self.
    # Adapted from rubinius'
    def flatten_with_optional_argument!(level=-1)
      level = Type.coerce_to(level, Integer, :to_int)
      return flatten_without_optional_argument! unless level >= 0

      ret, out = nil, []
      ret = recursively_flatten_finite(self, out, level)
      replace(out) if ret
      ret
    end

    alias_method_chain :flatten, :optional_argument
    alias_method_chain :flatten!, :optional_argument

    # Helper to recurse through flattening
    # Adapted from rubinius'; recursion guards are not needed because level is finite
    def recursively_flatten_finite(array, out, level)
      ret = nil
      if level <= 0
        out.concat(array)
      else
        array.each do |o|
          if o.respond_to? :to_ary
            recursively_flatten_finite(o.to_ary, out, level - 1)
            ret = self
          else
            out << o
          end
        end
      end
      ret
    end
    private :recursively_flatten_finite
  end # flatten & flatten!

  # index. Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  unless ([1].index{true} rescue false)
    def index_with_block(*arg)
      return index_without_block(*arg) unless block_given? && arg.empty?
      each_with_index{|o,i| return i if yield o}
      return nil
    end
    alias_method_chain :index, :block
    alias_method :find_index, :index
  end

  # pop. Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  unless ([1].pop(1) rescue false)
    def pop_with_optional_argument(n = Undefined)
      return pop_without_optional_argument if n == Undefined
      n = Type.coerce_to(n, Fixnum, :to_int)
      raise ArgumentError, "negative array size" if n < 0
      first = size - n
      first = 0 if first < 0
      slice!(first..size).to_a
    end
    alias_method_chain :pop, :optional_argument
  end

  # Standard in Ruby 1.9. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def product(*arg)
    # Implementation notes: We build an enumerator for all the combinations
    # by building it up successively using "inject" and starting from a trivial enumerator.
    # It would be easy to have "product" yield to a block but the standard
    # simply returns an array, so you'll find a simple call to "to_a" at the end.
    #
    trivial_enum = Enumerator.new{|yielder| yielder.yield [] }
    [self, *arg].map{|x| Type.coerce_to(x, Array, :to_ary)}.
      inject(trivial_enum) do |enum, array|
        Enumerator.new do |yielder|
          enum.each do |partial_product|
            array.each do |obj|
              yielder.yield partial_product + [obj]
            end
          end
        end
    end.to_a
  end unless method_defined? :product

  # rindex
  unless ([1].rindex{true} rescue false)
    def rindex_with_block(*arg)
      return rindex_without_block(*arg) unless block_given? && arg.empty?
      reverse_each.each_with_index{|o,i| return size - 1 - i if yield o}
      return nil
    end
    alias_method_chain :rindex, :block
  end

  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def sample(n = Undefined)
    return self[rand(size)] if n == Undefined
    n = Type.coerce_to(n, Fixnum, :to_int)
    raise ArgumentError, "negative array size" if n < 0
    n = size if n > size
    result = Array.new(self)
    n.times do |i|
      r = i + rand(size - i)
      result[i], result[r] = result[r], result[i]
    end
    result[n..size] = []
    result
  end unless method_defined? :sample

  # shift. Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  unless ([1].shift(1) rescue false)
    def shift_with_optional_argument(n = Undefined)
      return shift_without_optional_argument if n == Undefined
      n = Type.coerce_to(n, Fixnum, :to_int)
      raise ArgumentError, "negative array size" if n < 0
      slice!(0, n)
    end
    alias_method_chain :shift, :optional_argument
  end

  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def shuffle
    dup.shuffle!
  end unless method_defined? :shuffle

  # Standard in Ruby 1.8.7+. See official documentation[http://ruby-doc.org/core-1.9/classes/Array.html]
  def shuffle!
    size.times do |i|
      r = i + rand(size - i)
      self[i], self[r] = self[r], self[i]
    end
    self
  end unless method_defined? :shuffle!

end