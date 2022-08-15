set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
set val(rp)           AODV                     ;# routing protocol
set val(finish)       15		       ;# Finish time
set val(nn)           80	               ;# number of mobilenodes
set val(x)            500		       ;# X length [Note Take the value of x and y Equal]
set val(y)            500		       ;# Y length

set ns [new Simulator]

namespace import ::tcl::mathfunc::*

set tracefile [open wireless.tr w]
$ns trace-all $tracefile 
set namfile [open wireless.nam w]
$ns namtrace-all-wireless $namfile $val(x) $val(y)

set topo [new Topography]
$topo load_flatgrid $val(x) $val(y)
 
create-god $val(nn)
set channel1 [new $val(chan)]

# CONFIGURE AND CREATE NODES

$ns node-config  -adhocRouting $val(rp) \
          -llType $val(ll) \
                 -macType $val(mac) \
                 -ifqType $val(ifq) \
                 -ifqLen $val(ifqlen) \
                 -antType $val(ant) \
                 -propType $val(prop) \
                 -phyType $val(netif) \
                 -topoInstance $topo \
                 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace ON \
                 -movementTrace ON \
                 -channel $channel1

# Random Number Procedure
proc myRand {min max} {
    expr {int(rand() * ($max + 1 - $min)) + $min}
}


# Creation of nodes 
for {set i 0} {$i < $val(nn) } {incr i} {
   set n($i) [$ns node]
   $n($i) random-motion 0
}

set x(0) 0
set y(0) 0 

for {set i 1} {$i < $val(nn) } {incr i} {
 set d 0
 while {$d <10} {
     set a($i) [myRand 0 $val(x)]
     set b($i) [myRand 0 $val(y)]
     set semaphore 1
     for {set j 0} {$j < $i } {incr j} {
         set first [expr {pow ([expr $a($i)- $x($j)] ,2)}]
         set second [expr {pow ([expr $b($i)-$y($j)] ,2)}]
         set d [sqrt [expr $first+ $second ]]

         if { $d<10 } {
           set $semaphore 0
           break
         }
         }
        
        if { $semaphore == 1 }  {
           set x($i) $a($i)
           set y($i) $b($i) 
         } 
        
}
}


for {set i 0} {$i < $val(nn) } {incr i} {
 for {set j [ expr $i+1 ]} {$j < $val(nn) } {incr j} {
         set first [expr {pow ([expr $x($i)- $x($j)] ,2)}]
         set second [expr {pow ([expr $y($i)-$y($j)] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         #puts $d
}
}


# setting the cordinates 
for {set i 0} {$i < $val(nn) } {incr i} {
   $n($i) set X_ $x($i)
   $n($i) set Y_ $y($i)
   puts $tracefile "n($i)= $x($i)"
$ns initial_node_pos $n($i) 15
 
}

for {set i 0} {$i < $val(nn) } {incr i} {
set bool($i) 0
}


# FINDING THE PAIR 
set count 0

for {set i 0} {$i < $val(nn) } {incr i} {
  if { $bool($i) == 1 } { 
     continue
     }
 for {set j 0} {$j < $val(nn) } {incr j} {
  if { $bool($i) == 1 } { 
     break
     }
         if { $bool($j) == 1 ||  $i == $j } {
          continue        
          }
         set first [expr {pow ([expr $x($i)- $x($j)] ,2)}]
         set second [expr {pow ([expr $y($i)-$y($j)] ,2)}]
         set d [sqrt [expr $first+ $second ]]

         if { $d <= 20 } {
           set bool($i) 1
           set bool($j) 1
           set pairx($count) $i 
           set pairy($count) $j
           set count [expr $count+1]      
         }
         }
        
}

set length [array size pairy]
puts " "
puts "..........The pair at time stamp 0 is .............."
for {set i 0} {$i < $length } {incr i} {
  puts " $pairx($i) and  $pairy($i)"
}

set channelf1x(0) $pairx(0)
set channelf1y(0) $pairy(0)

set channelf2x(0) $pairx(1)
set channelf2y(0) $pairy(1)

#finding the distance greater then 40
set count 1
set c 1
set rec 0

set channellen1 [array size channelf1x]
for {set i 2} {$i < $length  } { incr i } {
set channellen1 [array size channelf1x]
set semaphore 1
 for {set j 0} { $j < $channellen1 } { incr j } {
         set first [expr {pow ([expr $x($pairy($i))- $x($channelf1x($j))] ,2)}]
         set second [expr {pow ([expr $y($pairy($i))- $y($channelf1x($j))] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         if { $d < 40 } {
                 set  rejectedx($rec) $pairx($i)
                 set  rejectedy($rec) $pairy($i)
                 set  rec [ expr $rec+1]  
           set semaphore 0
           break
          } 
         } 
        if { $semaphore == 1 }  {
           set channelf1x($count) $pairx($i)
           set channelf1y($count) $pairy($i)
           set count [expr $count+1]  
         }        
}

puts " "
puts " the channel f1 pair are ..."
set channellen1 [array size channelf1x]
for {set i 0} {$i < $channellen1 } {incr i} {
puts " $channelf1x($i) and $channelf1y($i) "

set tcp [new Agent/TCP]
set sink [new Agent/TCPSink]
$ns attach-agent $n($channelf1x($i)) $tcp
$ns attach-agent $n($channelf1y($i)) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 0 "$ftp start"

} 


set count 1
set c 1
set rec 0
set rejectedlen [array size rejectedx ]
for {set i 0} {$i < $rejectedlen  } { incr i } {
set channellen2 [array size channelf2x]
set semaphore 1
 for {set j 0} { $j < $channellen2 } { incr j } {
         set first [expr {pow ([expr $x($rejectedy($i))- $x($channelf2x($j))] ,2)}]
         set second [expr {pow ([expr $y($rejectedy($i))- $y($channelf2x($j))] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         if { $d < 40 } {
                 set  rejectx($rec) $rejectedx($i)
                 set  rejecty($rec) $rejectedy($i)
                 set  rec [ expr $rec+1]  
           set semaphore 0
           break
          } 
         } 
        if { $semaphore == 1 }  {
           set channelf2x($count) $rejectedx($i)
           set channelf2y($count) $rejectedy($i)
           set count [expr $count+1]  
         }        
}
puts " "
puts " the channel f2 pair are ..."
set channellen2 [array size channelf2x]
for {set i 0} {$i < $channellen2 } {incr i} {
puts " $channelf2x($i) and $channelf2y($i) "

set tcp [new Agent/TCP]
set sink [new Agent/TCPSink]
$ns attach-agent $n($channelf2x($i)) $tcp
$ns attach-agent $n($channelf2y($i)) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 0 "$ftp start"
} 

set rejectlen [array size rejectx ]
puts " "
puts "....REJECTED PAIRS ARE..."
for {set i 0} {$i < $rejectlen } {incr i} { 
puts " $rejectx($i) and $rejecty($i) "
}


#MOBILITY OF NODE 

for {set i 0} {$i < 10 } {incr i} { 
set mobx($i) [myRand 1 [expr $val(x)-1]]
set moby($i) [myRand 1 [expr $val(x)-1]]
set mobz($i) [myRand 1 [expr $val(x)-1]]
$ns at 1 "$n($i) setdest $mobx($i) $moby($i) $mobz($i) "
}



for {set i 0} {$i < $val(nn) } {incr i} {
if {$i < 10 } {
set x($i) $mobx($i)
set y($i) $moby($i)
}
set bool($i) 0

}

set c 0
set d 0

for {set i 0} {$i < $length } {incr i} {
  if { $bool($pairy($i)) == 1 } { 
     continue
     }
 for {set j 0} {$j < $val(nn) } {incr j} {
  if { $bool($pairy($i)) == 1 } { 
     break
     }
         if { $bool($j) == 1 ||  $j == $pairy($i) } {
          continue        
          }
         set first [expr {pow ([expr $x($pairy($i))- $x($j)] ,2)}]
         set second [expr {pow ([expr $y($pairy($i))-$y($j)] ,2)}]
         set d [sqrt [expr $first+ $second ]]

         if { $d <= 20 } {
           set bool($pairy($i)) 1
           set bool($j) 1
           set newx($c) $pairy($i)
           set newy($c) $j
           set c [expr $c+1]
           
         }
   
}
}

set size [array size newx]
puts "  "
puts "........ the new pairs after 1st mobility implimentation---------- "
for {set i 0} {$i < $size  } { incr i } {
puts "$newx($i) and $newy($i)"
}

set count 
set c 1
set rec 0
set size [array size newx]

for {set i 0} {$i < $size  } { incr i } {
set channellen1 [array size channelf1x]
set semaphore 1
 for {set j 0} { $j < $channellen1 } { incr j } {
         set first [expr {pow ([expr $x($newy($i))- $x($channelf1x($j))] ,2)}]
         set second [expr {pow ([expr $y($newy($i))- $y($channelf1x($j))] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         if { $d < 40 } {
                 set  failx($rec) $newx($i)
                 set  faily($rec) $newy($i)
                 set  rec [ expr $rec+1]  
                 set semaphore 0
                 break
          } 
         } 
        if { $semaphore == 1 }  {
           set channelf1x($channellen1) $newx($i)
           set channelf1y($channellen1) $newy($i) 
         }        
}

set c 1
set rec 0
set faillen [array size failx ]
for {set i 0} {$i < $faillen  } { incr i } {
set channellen2 [array size channelf2x]
set semaphore 1
 for {set j 0} { $j < $channellen2 } { incr j } {
         set first [expr {pow ([expr $x($faily($i))- $x($channelf2x($j))] ,2)}]
         set second [expr {pow ([expr $y($faily($i))- $y($channelf2x($j))] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         if { $d < 40 } {
                 set  rejx($rec) $failx($i)
                 set  rejy($rec) $faily($i)
                 set  rec [ expr $rec+1]  
           set semaphore 0
           break
          } 
         } 
        if { $semaphore == 1 }  {
           set channelf2x($channellen2) $failx($i)
           set channelf2y($channellen2) $faily($i)
         }        
}



set size2 [array size channelf2x]
set size1 [array size channelf1x]

puts " "
puts "..........channel f1 pairs...... "
for {set i 0} {$i < $size1 } {incr i} {
puts "$channelf1x($i) and $channelf1y($i)"

}

puts " "
puts "......channel f2 pairs....... "
for {set i 0} {$i < $size2 } {incr i} {
puts "$channelf2x($i) and $channelf2y($i)"

}

set rejlen [array size rejx ]
puts " "
puts "......rejected pairs....... "
for {set i 0} {$i < $rejlen } {incr i} {
puts "$rejx($i) and $rejy($i)"
}


for {set i 11} {$i < 21 } {incr i} { 
set mobx($i) [myRand 1 [expr $val(x)-1]]
set moby($i) [myRand 1 [expr $val(x)-1]]
set mobz($i) [myRand 1 [expr $val(x)-1]]
$ns at 7 "$n($i) setdest $mobx($i) $moby($i) $mobz($i) "
}

for {set i 11} {$i < 21 } {incr i} {
set x($i) $mobx($i)
set y($i) $moby($i)
}

for {set i 0} {$i < $val(nn) } {incr i} {
set bool($i) 0
}


# FINDING THE PAIR at 7 sec after mobility of nodes from 11 to 20 
set count 0

for {set i 11} {$i < 21 } {incr i} {
  if { $bool($i) == 1 } { 
     continue
     }
 for {set j 0} {$j < $val(nn) } {incr j} {
  if { $bool($i) == 1 } { 
     break
     }
         if { $bool($j) == 1 ||  $i == $j } {
          continue        
          }
         set first [expr {pow ([expr $x($i)- $x($j)] ,2)}]
         set second [expr {pow ([expr $y($i)-$y($j)] ,2)}]
         set d [sqrt [expr $first+ $second ]]

         if { $d <= 20 } {
           set bool($i) 1
           set bool($j) 1
           set pax($count) $i 
           set pay($count) $j
           set count [expr $count+1]      
         }
         }
        
}

set pairlen [array size pax]
puts " "
puts "......New Pairs after 2nd mobility....  "
for {set j 0} {$j < $pairlen } {incr j} {
puts " $pax($j) and $pay($j) "
}


set count 
set c 1
set rec 0

for {set i 0} {$i < $pairlen  } { incr i } {
set channellen1 [array size channelf1x]
set semaphore 1
 for {set j 0} { $j < $channellen1 } { incr j } {
         set first [expr {pow ([expr $x($pay($i))- $x($channelf1x($j))] ,2)}]
         set second [expr {pow ([expr $y($pay($i))- $y($channelf1x($j))] ,2)}]
         set d [sqrt [expr $first+ $second ]]
         if { $d < 40 } {
                 set sema 1
                 set channellen2 [array size channelf2x]
                 for {set j 0} { $j < $channellen2 } { incr j } {
                     set first [expr {pow ([expr $x($faily($i))- $x($channelf2x($j))] ,2)}]
                     set second [expr {pow ([expr $y($faily($i))- $y($channelf2x($j))] ,2)}]
                     set d [sqrt [expr $first+ $second ]]
                     if { $d < 40 } {
                       set  failex($rec) $pax($i)
                       set  failey($rec) $pay($i)
                       set  rec [ expr $rec+1]  
                       set sema 0
                       break
                      } 
                     } 
                 if { $sema == 1 }  {
                   set channelf2x($channellen2) $pax($i)
                   set channelf2y($channellen2) $pay($i)
                   }        
                  
           set semaphore 0
           break 
         } 
        if { $semaphore == 1 }  {
           set channelf1x($channellen1) $pax($i)
           set channelf1y($channellen1) $pay($i) 
         }        
}
}

set channellen1 [array size channelf1x]
puts " "
puts "....channelf1 pairs.... "
for {set j 0} { $j < $channellen1 } { incr j } {
puts "$channelf1x($j) and $channelf1y($j)"

set tcp [new Agent/TCP]
set sink [new Agent/TCPSink]
$ns attach-agent $n($channelf1x($j)) $tcp
$ns attach-agent $n($channelf1y($j)) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 11 "$ftp start"
}

set channellen2 [array size channelf2x]

puts " "
puts "....channelf2 pairs.... "
for {set j 0} { $j < $channellen2 } { incr j } {
puts "$channelf2x($j) and $channelf2y($j)"

set tcp [new Agent/TCP]
set sink [new Agent/TCPSink]
$ns attach-agent $n($channelf2x($j)) $tcp
$ns attach-agent $n($channelf2y($j)) $sink
$ns connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns at 11 "$ftp start"
}

puts " "
puts "....Rejected  pairs.... "
set faillen [array size failex]
for {set j 0} { $j < $faillen } { incr j } {
puts "$failex($j) and $failey($j)"
}

$ns at $val(finish) "finish "

proc finish {} {
    global ns tracefile namfile
    $ns flush-trace
    close $tracefile 
    exec nam wireless.nam &
    exit 0
}

puts "Start of simulation..."
$ns run
