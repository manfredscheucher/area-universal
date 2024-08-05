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
G,pos,F,labels,weights = parse_ipe_file(infile,unit_weights=1)



n = len(G)
m = len(F)


Z0 = [pos[i][0] for i in range(n)]+[pos[i][1] for i in range(n)]

epsilon = 0.0001
while True:
	print "F",F
	weights = {f:randint(0,1) for f in weights}
	face_weights = [weights[F[i]] for i in range(m)]
	print "weights",weights

	sbest = None
	sol = optimize.minimize(errf,Z0,method="Powell", options={'disp': False,'maxfev': n*10000,'maxiter': n*1000})
	print "------- computations done with Powell ------"
	print "status:",sol.message
	print "epsilon:",sol.fun

	if sol.fun > epsilon:
		sol = optimize.minimize(errf,Z0,method="Nelder-Mead", options={'disp': False,'maxfev': n*10000,'maxiter': n*1000})
		print "------- computations done with Nelder Mead ------"
		print "status:",sol.message
		print "epsilon:",sol.fun

	Z = sol.x
	pos2 = {i:(Z[i],Z[n+i]) for i in range(n)}

	print "solution:"
	for i in range(n):
		print "\t",labels[i],"->",round(pos2[i][0],3),round(pos2[i][1],3)

	G2 = copy(G)
	G2.set_pos(pos2)
	G2.relabel({i:labels[i] for i in range(n)})
	plot(G2).save(outfile)
	print "Graph6-string:",G2.graph6_string()
	print "wrote png file:",outfile

	if sol.fun > epsilon: exit()