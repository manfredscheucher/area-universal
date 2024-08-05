from sys import argv,stdout
from scipy import optimize
from itertools import combinations
import xml.etree.ElementTree as ET


load("basics.sage")



if len(argv) < 2:
	print "usage:",argv[0],"ipe-file"
	exit()

infile = argv[1]
outfile = infile+".png"
G,pos,F,labels,weights = parse_ipe_file(infile)


n = len(G)
m = len(F)


#Z0 = [pos[i][0] for i in range(n)]+[pos[i][1] for i in range(n)]
W0 = [1 for i in range(len(G.edges()))]


print "F",F
face_weights = [weights[F[i]] for i in range(m)]
sbest = None
"""
sol = optimize.minimize(errf_W,W0,method="Powell", options={'disp': False,'maxfev': n*10000,'maxiter': n*1000})
print "------- computations done with Powell ------"
print "status:",sol.message
print "epsilon:",sol.fun
"""

epsilon = 0.0001

sol = optimize.minimize(errf_W,W0,method="Nelder-Mead", options={'disp': False,'maxfev': n*10000,'maxiter': n*1000})
print "------- computations done with Nelder-Mead ------"
print "status:",sol.message
print "epsilon:",sol.fun


W = sol.x
pos2 = pos_from_W(W)

print "solution:"
for i in range(n):
	print "\t",labels[i],"->",round(pos2[i][0],3),round(pos2[i][1],3)

G.set_pos(pos2)
G.relabel({i:labels[i] for i in range(n)})
plot(G).save(outfile)
print "Graph6-string:",G.graph6_string()
print "wrote png file:",outfile

