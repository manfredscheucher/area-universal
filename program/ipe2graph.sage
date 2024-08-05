#!/usr/bin/python
from sys import argv
import xml.etree.ElementTree as ET

load("basics.sage")

if len(argv)==1:
    print "usage:",argv[0],"ipe-file"
    print "description: read the graph from an ipe file"
    exit()

infile = argv[1]
outfile = infile+".png"
G,pos,F,labels,weights = parse_ipe_file(infile)

print "graph6string:",G.graph6_string()
print "pos =",G.get_pos()
print "E =",G.edges(labels=False)
print "F =",[[u for (u,v) in f] for f in G.faces()]

