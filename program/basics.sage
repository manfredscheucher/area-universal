
def tutte_layout(G,outer_face,weights):
	V = G.vertices()
	pos = dict()
	l = len(outer_face)

	for i in range(l):
		ai = pi/4+ pi*2*i/l
		pos[outer_face[i]] = (cos(ai),sin(ai))
	
	n = len(V)
	M = zero_matrix(RR,n,n)
	b = zero_matrix(RR,n,2)

	for i in range(n):
		v = V[i]
		if v in pos:
			M[i,i] = 1
			b[i,0] = pos[v][0]
			b[i,1] = pos[v][1]
		else:
			nv = G.neighbors(v)
			s = 0
			for u in nv:
				j = V.index(u)
				wu = weights[u,v]
				s += wu
				M[i,j] = -wu
			M[i,i] = s

	sol = M.pseudoinverse()*b
	return {V[i]:sol[i] for i in range(n)}


def same_coordinate(pos,i):
	for j in range(n):
		if i != j and pos[i]==pos[j]: 
			return True
	return False

def o3(pos,a,b,c):
	ax,ay = pos[a]
	bx,by = pos[b]
	cx,cy = pos[c]
	return sgn((bx-ax)*(cy-ay)-(cx-ax)*(by-ay))

def edge_crossing(pos,(a,b),(c,d)):
	if o3(pos,a,b,c)*o3(pos,a,b,d) == 1: return False
	if o3(pos,c,d,a)*o3(pos,c,d,b) == 1: return False
	return True # collinear is considered as "crossing"... 
	# to avaid coll. points 
	
def face_area(pos,f):			
	X = [pos[v][0] for v in f]
	Y = [pos[v][1] for v in f]
	return sum(X[i-1]*Y[i]-Y[i-1]*X[i] for i in range(len(f)))/2



sbest = None


def pos_from_W(W):
	V = G.vertices()
	E = G.edges(labels=False)
	n = len(V)
	weights = {}
	for i in range(n):
		for j in range(n):
			ij = (min(i,j),max(i,j))
			weights[V[i],V[j]] = W[E.index(ij)] if ij in E else 0
	return tutte_layout(G,outerface,weights)

def errf_W(W):
	W = [RR(w) for w in W]

	G2 = copy(G)
	pos2 = pos_from_W(W)
	G2.set_pos(pos2)

#	if not G2.is_drawn_free_of_edge_crossings():
#		return 9999999999999999999
	for e,f in combinations(G2.edges(labels=False),2):
		if not set(e) & set(f) and  edge_crossing(pos2,e,f):
			return 999999999999999999999

	s = 0
	areas = [face_area(pos2,f) for f in F]

	norm1 = sum(areas)
	norm2 = sum(face_weights)
	for j in range(m):
		s += abs(areas[j]/RR(norm1)-face_weights[j]/RR(norm2))^2

	global sbest
	if sbest == None or s < sbest: 
		sbest = s
		print "best",s,"\r",
		stdout.flush()
	return s

def errf(Z):
	Z = [RR(z) for z in Z]
	G2 = copy(G)
	pos2 = {i:(Z[i],Z[n+i]) for i in range(n)}
	G2.set_pos(pos2)

#	if not G2.is_drawn_free_of_edge_crossings():
#		return 9999999999999999999
	for e,f in combinations(G2.edges(labels=False),2):
		if not set(e) & set(f) and  edge_crossing(pos2,e,f):
			return 999999999999999999999

	s = 0
	areas = [face_area(pos2,f) for f in F]

	norm1 = sum(areas)
	norm2 = sum(face_weights)
	for j in range(m):
		s += abs(areas[j]/RR(norm1)-face_weights[j]/RR(norm2))^2

	global sbest
	if sbest == None or s < sbest: 
		sbest = s
		print "best",s,"\r",
		stdout.flush()
	return s

def parse_ipe_file(filepath,unit_weights=False):
	tree = ET.parse(filepath)
	root = tree.getroot()
	page = root.find('page')


	# lade knoten
	P = []
	for u in page.iterfind('use'):
		attr = u.attrib
		if attr['name']=='mark/disk(sx)':
			if "pos" not in attr: attr["pos"] = "0 0"
			x,y = [float(t) for t in attr['pos'].split(" ")]

			if 'matrix' in attr:
				M = [float(t) for t in attr['matrix'].split(" ")]
				x0 = x
				y0 = y
				x = M[0]*x0+M[2]*y0+M[4]
				y = M[1]*x0+M[3]*y0+M[5]

			x = round(x,2)
			y = round(y,2)
			p = (x,y)
			assert(p not in P) # no two vertices at same point
			P.append(p)
	print "vertices:",len(P),P


	# lade kanten
	E = []
	for u in page.iterfind('path'):
		attr = u.attrib
		if 'matrix' in attr:
			M = [float(t) for t in attr['matrix'].split(" ")]

		lines = u.text.split("\n")
		pts = []
		for l in lines:
			if l == '': continue
			x,y = [float(z) for z in l.split()[:2]]
			if 'matrix' in attr:
				x0 = x
				y0 = y
				x = M[0]*x0+M[2]*y0+M[4]
				y = M[1]*x0+M[3]*y0+M[5]
			x = round(x,2)
			y = round(y,2)
			p = (x,y)
			if p not in P:
				print "WARNING:",p,"not a point of",P 
				continue
			i = P.index(p)
			pts.append(i)
		assert(len(pts) == 2) # no hypergraph

		pts.sort()
		e = tuple(pts)
		if e not in E:
			E.append(e)
	print "edges:",len(E),E


	pos = {i:P[i] for i in range(len(P))}
	G = Graph(data=E,pos=pos)
	F = G.faces()
	F = [tuple(x for (x,y) in f) for f in F]


	# finde und entferne outerface aus F ...  
	maxarea=0
	maxarea_index=None
	for j in range(len(F)):
		area = abs(face_area(pos,F[j]))
		if area > maxarea:
			maxarea_index = j
			maxarea = area
	
	global outerface
	outerface = F[maxarea_index]

	del F[maxarea_index] # remove outerface
	print "faces:",len(F),F

	weights = {f:1 for f in F} if unit_weights else {}
	labels = {}
	# lade vertex labels & face weights
	for u in page.iterfind('text'):
		attr = u.attrib
		if "pos" not in attr: attr["pos"] = "0 0"
		x,y = [float(t) for t in attr['pos'].split(" ")]

		if 'matrix' in attr:
			M = [float(t) for t in attr['matrix'].split(" ")]
			x0 = x
			y0 = y
			x = M[0]*x0+M[2]*y0+M[4]
			y = M[1]*x0+M[3]*y0+M[5]

		x = round(x,2)
		y = round(y,2)
		p = (x,y)
		if attr['stroke']=='black':
			if p not in P:
				print "ERROR: invalid vertex label",u.text,"@",p
				exit()
			labels[P.index(p)] = u.text

		if attr['stroke']=='red':
			found = 0
			for f in F:
				hull = Polyhedron([pos[v] for v in f]+[p]).vertices_list()
				if list(p) not in hull: # the function returns notation [a,b] (i.e. a list) instead of (a,b) (i.e. a tuple)
					found += 1
					weights[f] = int(u.text)
			if found != 1:
				print "ERROR: face weight lies in",found,"faces (should be 1)"
				exit()

	print "labels:",labels
	print "weights:",weights

	for p in P:
		if not P.index(p) in labels:
			labels[P.index(p)] = str(P.index(p))
		assert(P.index(p) in labels) # every vertex needs a label

	for f in F:
		assert(f in weights) # every face needs a weight

	return G,pos,F,labels,weights
 
