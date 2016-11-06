# Introducing the subnet_calc gem

    require 'subnet_calc'

    sc = SubnetCalc.new hosts: 40
    sc.to_h #=> {:class_type=>"C", :magic_number=>64, :hosts=>62, :subnet_mask=

    puts sc.to_s

Output:

<pre>
Subnet calculator
=================

Inputs: 

  hosts: 40

Summary
-------

* Network class: C
* magic number: 64
* hosts per subnet: 62
* subnet mask: 255.255.255.192
* subnet bitmask: 11111111.11111111.11111111.11000000
* prefix bit-length: 26
* range: 192.168.0.1-192.168.0.62

* subnet_bits: 2
* maximum subnets: 4



Breakdown
---------

4th octet:

  | 128 | 64  | 32  | 16  | 8   | 4   | 2   | 1   |
  |:----|:----|:----|:----|:----|:----|:----|:----|
  | 1   | 1   | 0   | 0   | 0   | 0   | 0   | 0   |
  | /25 | /26 | /27 | /28 | /29 | /30 | /31 | /32 |


### Subnets


  | Network | 1st | last | broadcast |
  |:--------|:----|:-----|:----------|
  | 0       | 1   | 62   | 63        |
  | 64      | 65  | 126  | 127       |
  | 128     | 129 | 190  | 191       |
  | 192     | 193 | 254  | 255       |


-----------------------------------------------

</pre>


## Resources

* subnet_calc https://rubygems.org/gems/subnet_calc
* Online IP Subnet Calculator http://www.subnet-calculator.com/
* Subnetwork https://en.wikipedia.org/wiki/Subnetwork
* Converting a decimal to binary http://www.jamesrobertson.eu/snippets/2013/mar/19/converting-a-decimal-to-binary.html
* Using the Table-formatter gem to output a table in Markdown format http://www.jamesrobertson.eu/snippets/2016/jul/12/using-the-table-formatter-gem-to-output-a-table-in-markdown-format.html
* Ruby refinements in action http://www.jamesrobertson.eu/snippets/2014/jan/20/ruby-refinements-in-action.html
* IP Addresses and Subnetting https://www.youtube.com/watch?v=rs39FWDhzDs


subnetting subnet calc gem network
