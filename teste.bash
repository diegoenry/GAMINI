#!/bin/bash
while read line
do
  let num=$num+1
  sbrubbles[$num]=$line
done < disp.dat

echo ${sbrubbles[1]}
echo ${sbrubbles[2]}

