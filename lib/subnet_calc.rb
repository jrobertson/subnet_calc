#!/usr/bin/env ruby

# file: subnet_calc.rb


require 'kvx'
require 'ostruct'
require 'table-formatter'


module Ordinals

  refine Fixnum do
    def ordinal
      self.to_s + ( (10...20).include?(self) ? 'th' : 
                    %w{ th st nd rd th th th th th th }[self % 10] )
    end
  end
end

class SubnetCalc

  using Ordinals

  attr_reader :to_h, :octets

  def initialize(inputs={})

    @inputs = inputs
    default_inputs = {hosts: nil, ip: '192.168.0.0', prefix: nil}.merge(inputs)
    
    # Using the input(s) supplied:

    hosts, prefix = %i(hosts prefix).map {|x| default_inputs[x]}
    

    @prefixes = 1.upto(32).each_slice(8).to_a
    
=begin
    #=> [
         [1, 2, 3, 4, 5, 6, 7, 8], [9, 10, 11, 12, 13, 14, 15, 16], 
         [17, 18, 19, 20, 21, 22, 23, 24], [25, 26, 27, 28, 29, 30, 31, 32]
        ]
=end
    

    octets = @prefixes.map.with_index do |octet, j|

      a = octet.map.with_index do |prefix, i|
        
        decimal = 2 ** (octet.length - 1 - i )

        h = {
              prefix: prefix,
              decimal: decimal,
              hosts_per_subnet: (2 ** 8) ** (@prefixes.length - 1 - j) * decimal
            }

        OpenStruct.new h
        
      end

      OpenStruct.new mask: nil, bits: a

    end
    
    @octets = octets
    

    # ------------------------------------


    octet_n, col, class_type = if hosts then
      
      hosts_per_subnet = octets.flat_map.with_index do |octet,i| 
        octet.bits.map.with_index {|y,j| [i, j, y.hosts_per_subnet] }
      end
        
      # find the smallest decimal value to match the 
      # required number of hosts on a network    
      
      *r, _ = hosts_per_subnet.reverse.detect {|x| x.last >  hosts + 1}    
      
      network = case hosts
      when 1..254
        'c'
      when 255..65534
        'b'
      else
        'a'
      end
      
      (r + [network])
    
    elsif prefix

      prefixes = @prefixes.flat_map.with_index do |octet,i|
        octet.map.with_index {|x,j| [i, j, x]}
      end
      
      *r, _ = prefixes.detect {|x| x.last == prefix}
      
      network = case prefix
      when 24..32
        'c'
      when 16..23
        'b'
      else
        'a'
      end
      
      (r + [network])
    end    


    # Identify the network bits and the host bits

    classes = ('a'..'d')

    # identify the initial network bits for a class *a,b or c*

    class_n = (classes.to_a.index(class_type) + 1)

    network_bits = class_n.times.map {|x| Array.new(8, 1)}
    host_bits = (classes.to_a.length - class_n).times.map {|x| Array.new(8, 0)}
    address_bits = network_bits + host_bits

    # add the mask to each octet

    octets.each.with_index do |octet, i|
      octet.mask = address_bits[i].join.to_i(2)
    end


    bit = octets[octet_n].bits[col]

    magic_number, hosts_per_subnet, prefix = bit.decimal, 
        bit.hosts_per_subnet, bit.prefix
    
    n =  col

    # add the new mask to the octet

    octets[octet_n].mask = octets[octet_n].bits.map(&:decimal)[0..n].inject(:+)
    subnet_mask = octets.map(&:mask).join('.')
    
    subnet_bits = (subnet_mask.split('.')[class_n]).to_i.to_s(2).count("1")
    
    no_of_subnets = segments = 2 ** (subnet_bits)    

    subnets = case class_type
    when 'c'
      class_subnets(segments, hosts_per_subnet)
    when 'b'
      class_b_subnets(256 / segments, bit.decimal)
    when 'a'
      class_a_subnets(256  ** 2 / segments, bit.decimal)      
    end

    ip = (default_inputs[:ip] + ' ') .split('.')[0..octet_n-1]
    
    first_ip = (ip + [subnets.first.first]).join('.')
    last_ip = (ip + [subnets.first.last]).join('.')
    
    
    result = {
      class_type: class_type.upcase,
      magic_number: magic_number,
      hosts: hosts_per_subnet - 2,
      subnet_mask: subnet_mask,
      subnet_bitmask: subnet_mask.split('.').map \
                                  {|x| ('0' * 7 + x.to_i.to_s(2))[-8..-1]},
      prefix: prefix,
      subnets: subnets,
      range: "%s-%s" % [first_ip, last_ip],
      subnet_bits:  subnet_bits,
      max_subnets: 2 ** (subnet_bits)
    }

    @octet_n = octet_n
    @h = result
  end


  def to_s()

    tfo = TableFormatter.new

    tfo.source = @h[:subnets].map.with_index do |x,i|
      ([i+1] + x.to_h.values).map(&:to_s)
    end
    
    tfo.labels = %w(index: Network: 1st: last: broadcast:)
    full_subnets_table = tfo.display(markdown: true).to_s
    
    subnets_table = if full_subnets_table.lines.length > 14 then
      (full_subnets_table.lines[0..13] + ["\n    ...  "]).join
    else
      full_subnets_table
    end

    # octet broken down

    tfo2 = TableFormatter.new

    prefixes = @prefixes[@octet_n].map {|x| '/' + x.to_s}
    tfo2.source = [@h[:subnet_bitmask][@octet_n].chars, prefixes]
    tfo2.labels = 8.times.map {|n| (2 ** n).to_s + ':' }.reverse
    octet_table = tfo2.display(markdown: true).to_s

<<EOF


Subnet calculator
=================

Inputs: 

#{Kvx.new(@inputs).to_s.lines.map {|x| ' ' * 2 + x}.join}

Summary
-------

* Network class: #{@h[:class_type]}
* magic number: #{@h[:magic_number]}
* hosts per subnet: #{@h[:hosts]}
* subnet mask: #{@h[:subnet_mask]}
* subnet bitmask: #{@h[:subnet_bitmask].join('.')}
* prefix bit-length: #{@h[:prefix]}
* range: #{@h[:range]}

* subnet_bits: #{@h[:subnet_bits]}
* maximum subnets: #{@h[:max_subnets]}



Breakdown
---------

#{(@octet_n + 1).ordinal} octet:

#{indent octet_table}

### Subnets


#{indent subnets_table}

-----------------------------------------------

EOF

  end

  def to_h()
    @h
  end
  
  private  
  
  def class_subnets(n, block_size)
    
    i = 0
    
    subnets = n.times.inject([]) do |r,n|
      
      broadcast = i + block_size - 1
      first = i + 1
      last = broadcast - 1
        
      h = if block_given? then
        yield(i,first,last,broadcast)
      else
        { network: i, first: first, last: last, broadcast: broadcast }
      end
      i += block_size      
      
      r << OpenStruct.new(h)
      
    end    
    
  end    
  
  def class_b_subnets(n, block_size)
    
    class_subnets(n, block_size) do |network, first, last, broadcast|
      
      {
        network: [network, 0].join('.'), 
        first: [network, 1].join('.'), 
        last: [broadcast, 254].join('.'), 
        broadcast: [broadcast, 255].join('.')
      }
                
    end    
    
  end  

  def class_a_subnets(n, block_size)
    
    class_subnets(n, block_size) do |network, first, last, broadcast|
      
      {
        network: [network, 0, 0].join('.'), 
        first: [network, 1, 1].join('.'), 
        last: [broadcast, 255, 254].join('.'), 
        broadcast: [broadcast, 255, 255].join('.')
      }
                
    end    
    
  end    
  
  def indent(s, i=2)
    s.lines.map{|x| ' ' * i + x}.join
  end
end