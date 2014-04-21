class Treemap
  attr_reader :full, :build_nodes, :build_sums
  def initialize(source_hash)
    @source_hash = source_hash 
    @value_sum_hash = {}
    @treemap = {}
  end

  # def build_sums(hash,branch_total=0)
  #   leaf_total = 0
  #   hash.each do |k,v|
  #     unless v.class == Hash
  #       leaf_total = leaf_total + v
  #     else
  #       branch_total = branch_total+build_sums(v,branch_total)
  #     end
  #   end
  #   p branch_total+leaf_total
  #   return branch_total+leaf_total
  # end

  def full
    { "name" => "All",
      "children" => build_nodes(@source_hash) }
  end

  def build_nodes(hash)
    leaf_array = []
    hash.each do |k,v|
      next if k == :sum
      # sum = hash[k][:sum]
      key_hash = { "name" => k.to_s }
      unless v.class == Hash
        key_hash["name"] = key_hash["name"] + " (#{v/2.0} hours)"
        value_hash =  { "value" => v }
      else
        sum = v[:sum]
        key_hash["name"] = key_hash["name"] + " (#{sum/2.0} hours)"
        value_hash = { "children" => build_nodes(v) }
      end
      leaf_array.push( key_hash.merge!(value_hash) )
    end
    return leaf_array
  end

end