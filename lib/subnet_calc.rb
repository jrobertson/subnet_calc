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

  attr_reader :to_h

  def initialize(inputs={hosts: 254})

    @inputs = inputs
    default_inputs = {hosts: 254, ip: '192.168.0.0'}.merge(inputs)

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
    
    hosts_per_subnet = octets.map.with_index do |x,i| 
      x.bits.map.with_index {|y,j| [i, j, y.hosts_per_subnet] }
    end.flatten(1)
    

    # determine what class of network we are using

    class_type = 'c'

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

    # ------------------------------------

    # Using the input(s) supplied:

    hosts = default_inputs[:hosts]



    # find the smallest decimal value to match the 
    # required number of hosts on a network    
    
    octet_n, col = hosts_per_subnet.reverse.detect {|x| x.last >  hosts}    

    bit = octets[octet_n].bits[col]

    magic_number, prefix = bit.hosts_per_subnet, bit.prefix
    no_of_subnets = (2 ** 8) / bit.decimal

    
    n =  col

    # add the new mask to the octet

    octets[octet_n].mask = octets[octet_n].bits.map(&:decimal)[0..n].inject(:+)
    subnet_mask = octets.map(&:mask).join('.')

    subnets = no_of_subnets.times.inject([]) do |r,n|
      
      i = r.last ? r.last.network + magic_number : 0

      broadcast = i + magic_number - 1
      first = i + 1
      last = broadcast - 1
      r << OpenStruct.new({network: i, first: first, last: last, 
                           broadcast: broadcast})
    end
    
    ip = (default_inputs[:ip] + ' ') .split('.')
    ip[class_n] = subnets.first.first
    first_ip = ip.join('.')
    ip[class_n] = subnets.first.last
    last_ip = ip.join('.')

    result = {
      class_type: class_type.upcase,
      magic_number: magic_number,
      hosts: magic_number - 2,
      subnet_mask: subnet_mask,
      subnet_bitmask: subnet_mask.split('.').map {|x| x.to_i.to_s(2)},
      prefix: prefix,
      subnets: subnets,
      range: "%s-%s" % [first_ip, last_ip],
      subnet_bits: n+1,
      max_subnets: no_of_subnets
    }

    @octet_n = octet_n
    @h = result
  end


  def to_s()


    tfo = TableFormatter.new

    tfo.source = @h[:subnets].map{|x| x.to_h.values.map(&:to_s) }
    tfo.labels = %w(Network 1st last broadcast)
    subnets_table = tfo.display(markdown: true).to_s

    # octet broken down

    tfo2 = TableFormatter.new

    prefixes = @prefixes[@octet_n].map {|x| '/' + x.to_s}
    tfo2.source = [@h[:subnet_bitmask][@octet_n].chars, prefixes]
    tfo2.labels = 8.times.map {|n| (2 ** n).to_s }.reverse
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
* hosts per subnet (magic number - 2 ): #{@h[:hosts]}
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
  
  def indent(s, i=2)
    s.lines.map{|x| ' ' * i + x}.join
  end
end