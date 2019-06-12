#coding: utf-8

if __debug__: from .debug import *



"""
Core logic in cython (run faster)
"""






cdef class Echiquier:
	"""Cette classe représente l'echiquier, sous forme d'un tableau de 8 sur 8 (listes imbriquées).
	On peut accéder à une case en faisant echiquier[x][y].
	Pour x=0 ou y=0, echiquier[x][y] = None
	Sinon, cette classe contient des objets Piece()
	"""

	cdef list echiquier
	cdef public object j1,j2
	cdef readonly set piece_j1, piece_j2

	def __init__(self,joueur1,joueur2,fill=True):
		"""On passe en argument les deux joueurs, puis une liste si il y'en a une de déjà créé (pour une copie).
		le paramètre 'full' sert en l'absence de 'echiquier' : il détermine si l'échiquier sera généré avec ou sans les pièces dessus"""

		echiquier = [None] + [[None]*9 for i in range(8)]
		if fill:
			for i,Class in enumerate(LIGNE_PIECE_FOND[1:]):
				i+=1
				echiquier[1][i] = Class((1,i),self,joueur1)
				echiquier[8][i] = Class((8,i),self,joueur2)
			for i,Class in enumerate(LIGNE_PION[1:]):
				i+=1
				echiquier[2][i] = Class((2,i),self,joueur1)
				echiquier[7][i] = Class((7,i),self,joueur2)
			for i in range(3,7):
				for j in range(1,9):
					echiquier[i][j] = PieceVide((i,j),self)
		else:
			echiquier = [None]+[[None]*9 for i in range(8)]
		self.echiquier = echiquier
		self.j1 = joueur1
		self.j2 = joueur2
		#On remplit les sets de pièces, par flemme de réécrire le code au dessus
		self.piece_j1 = set()
		self.piece_j2 = set()
		for piece in self:
			if piece:
				if piece.joueur is joueur1:
					self.piece_j1.add(piece)
				else:
					self.piece_j2.add(piece)


	def __getitem__(self,int value):
		"""Permet d'accéder au tableau avec les pièces"""
		return self.echiquier[value]

	def __setitem__(self,int indice,value):
		"""Permet de modifier le tableau avec les pièces"""
		self.echiquier[indice] = value

	def __iter__(self):
		cdef i,j
		for i in range(1,9):
			for j in range(1,9):
				yield self.get(i,j)

	def get(self,int y,int x):
		"""echiquier.get(y,x) est équivalent à echiquier[y][x] (mais plus performant)"""
		cdef list ligne =  self.echiquier[y]
		return ligne[x]

	cpdef set get_piece_by_joueur(self,joueur):
		if joueur is self.j1:
			return self.piece_j1
		elif joueur is self.j2:
			return self.piece_j2
		else:
			raise ValueError("Votre joueur n'existe pas")

	cpdef set get_piece_by_couleur(self,bint couleur):
		if self.j1.couleur is couleur:
			return self.piece_j1
		else:
			return self.piece_j2

	def copie(self):
		"""Crée une copie de l'echiquier : toutes les pièces sont copiés, mais on ne va pas plus profondément
		(les joueurs des pièces restent les mêmes références)"""
		nvx_echiquier = Echiquier(self.j1,self.j2,fill=False)
		nvx_echiquier.piece_j1 = set()
		nvx_echiquier.piece_j2 = set()
		for piece in self:
			nouv_piece = type(piece)(piece.coordonnes,nvx_echiquier,piece.joueur)
			nvx_echiquier[nouv_piece.coordonnes[0]][nouv_piece.coordonnes[1]] =  nouv_piece
			if piece.joueur is self.j1:
				nvx_echiquier.piece_j1.add(nouv_piece)
			elif piece.joueur is self.j2:
				nvx_echiquier.piece_j2.add(nouv_piece)

		return nvx_echiquier


	def get_value(self,joueur):
		cdef int gentil = 0
		cdef int mechant = 0
		for piece in self.get_piece_by_joueur(joueur):
			gentil += VALEUR_PIECE[piece.__class__]
		for piece in self.get_piece_by_couleur(not joueur.couleur):
			mechant += VALEUR_PIECE[piece.__class__]

		return gentil - mechant


	def temp_mvt(self,piece,cible):
		"""
		Effectue un mouvement temporaire.
		On passe en paramètre la pièce qui se déplace, et la pièce qui se fait remplacer.
		Retourne un tuple à envoyer à 'reset_mvt'
		"""
		nouvelle_piece = piece >> cible
		return (piece,cible,nouvelle_piece)


	def reset_mvt(self,infos):
		"""
		Annule le mouvement effectué par temp_mvt.
		Prend en paramètre la pièce qui s'était déplacé, ainsi que sa cible.
		NE DOIT PAS ÊTRE APPELLE AVEC DES PARAMETRES DIFFERENTS QUE CEUX PASSE A "temp_mvt".
		Il faut garder le même ordre d'appel (pas reset un temp_mvt avant le dernier à avoir été fait).
		"""
		piece, cible, piece_vide = infos
		if cible.joueur is self.j1:
			self.piece_j1.add(cible)
		elif cible.joueur is self.j2:
			self.piece_j2.add(cible)
		piece >> piece_vide
		self[cible.coordonnes[0]][cible.coordonnes[1]] = cible



	def get_all_mvt(self,joueur):
		"""Générateur qui renvoie tout les mouvements 1 à 1"""
		for piece in self.get_piece_by_joueur(joueur):
			yield from piece.liste_mvt()


	def __repr__(self):
		"""Uniquement utilisé pour debug"""
		a = ''
		a += '     '
		for x in range(1,9):
			a += LETTRE_CHIFFRE[x]
			a += "    "
		a += '\n'
		a += "   "
		for loop in range(8*5+1):
			a += '-'
		a += '\n'
		for lettre in range(8,0,-1):
			a += str(lettre)
			a += '  |'
			for chiffre in range(1,9):
				piece = self[lettre][chiffre]
				if not piece:
					a += '    |'
				else:
					couleur = piece.couleur[0]
					a+=piece.type[:2].title()
					a += ' '
					a += couleur
					a += '|'
			a +=' '
			a += str(lettre)
			a += '  \n   '
			for loop in range(8*5 + 1):
				a += '-'
			a+= '\n'
		a += '     '
		for i in range(1,9):
			a+=LETTRE_CHIFFRE[i]
			a+='    '
		a += '\n'   
		return a

	def repr_indent(self,indent):
		"""For debug"""
		x = repr(self)
		return '\n'.join('\t'*indent + i for i in x.split('\n'))




class Joueur:
	"""Classe représentant le joueur, elle est passé en argument à toute les pièces entre autre
	On connait son nom, si c'est une IA, sa difficulté..."""

	def __init__(self,couleur,classe = 'IA',nom = '',difficulte = 0,adversaire=None):
		"""On passe en arguments la couleur (True ou False), le nom (facultatif),et le type de joueur ('IA' ou 'joueur').
		Si le nom n'est pas renseigné, un nom est choisi aléatoirement"""
		self.couleur = couleur
		if  not nom:
			path = Path(__file__).parent/'data'/'prenoms.txt'
			with open(path,'r') as f:
				lignes = f.readlines()
				nom = random.choice(lignes)
				nom = nom[0] + nom[1:].lower()
				nom = nom[:-1]

		self.nom = nom
		if classe == 'IA':
			self.nom += ' (bot)'
			self.difficulte = difficulte
		self.type = classe

		if adversaire is not None:
			self.adversaire = adversaire
			adversaire.adversaire = self


	def __repr__(self):
		"""Renvoie uniquement le nom du joueur"""
		return self.nom


	@property
	def couleur_p(self):
		"""Pour savoir la couleur, à des fins d'affichage"""
		if self.couleur:
			return 'blanc'
		else:
			return 'noir'




LETTRE_CHIFFRE = [None,'A','B','C','D','E','F','G','H']

class Piece:
	"""La base de toutes les pièces"""

	def __init__(self,coord,echiquier,joueur):
		"""On passe en arguments les coordonnées de la pièce, une référence à l'echiquier sur lequelle elle est, et son joueur"""
		self.coordonnes = coord
		self.joueur = joueur
		self.echiquier = echiquier

	def mvt(self,cible):
		"""On change les coordonnés de la pièce, et on modifie l'echiquier en conséquence"""
		if cible.joueur is self.echiquier.j1:
			self.echiquier.piece_j1.remove(cible)
		elif cible.joueur is self.echiquier.j2:
			self.echiquier.piece_j2.remove(cible)
		y,x = self.coordonnes[0],self.coordonnes[1]
		t = PieceVide(self.coordonnes,self.echiquier)
		self.echiquier[y][x] = t
		coord = cible.coordonnes
		self.coordonnes = coord
		self.echiquier[coord[0]][coord[1]] = self
		return t


	def liste_mvt(self,bint echec_non_compris=False):
		"""
		Renvoie un générateur de tuple, sous la forme (Piece_qui_bouge,Piece_tue)
		Une PieceVide va renvoyer un générateur vides
		Si echec vaut True, la liste ne contiendra pas les mouvements qui aboutissent à un échec
		"""
		liste_mvt_possible = self._calcul_mvt()
		if echec_non_compris:
			for self_,cible in liste_mvt_possible:
				temp = self.echiquier.temp_mvt(self,cible)
				t = False
				if not echec_roi(self.echiquier,self.joueur.couleur):
					t = True
				self.echiquier.reset_mvt(temp)
				if t:
					yield (self_,cible)
		yield from liste_mvt_possible




	def __rshift__(self,value):
		"""On peut utiliser 'piece.mvt(cible)' en écrivant 'piece >> cible'"""
		return self.mvt(value)

	@property
	def couleur(self):
		"""Pour savoir la couleur, à des fins d'affichage"""
		if self.joueur.couleur:
			return 'blanc'
		return 'noir'

	@property
	def coord(self):
		"""Les coordonnées avec la lettre"""
		return LETTRE_CHIFFRE[self.coordonnes[1]],self.coordonnes[0]

	def equiv_autre_echiquier(self,echiquier):
		"""Renvoie la pièce équivalente sur un autre échiquier (à faire après une copie)"""
		return echiquier[self.coordonnes[0]][self.coordonnes[1]]


	@property
	def type(self):
		"""Renvoie le type de la pièce ('cavalier', 'pion')"""
		for cle, valeur in TYPE_PIECE.items():
			if isinstance(self,cle):
				return valeur
		return "Vide"

	def __repr__(self):
		return f"{self.type} {self.coord}, de {self.joueur.nom} {self.couleur} ({self.joueur.type})"








class PieceVide(Piece):
	"""Objet qui remplit les cases vides de l'echiquier.
	Elle n'a pas de liste de mouvement, et elle vaut False"""
	def __init__(self,coord,echiquier,joueur = None):
		#if joueur is not None:
		#    raise ValueError("Une pièce vide n'a pas de joueur")
		super().__init__(coord,echiquier,joueur)
		self.joueur = None
	
	def _calcul_mvt(self):
		return	#Pas de mouvement, on a donc un générateur vide
		yield

	def __bool__(self):
		"""Renvoie False :
		On peut donc écrire :

		>>> if piece:
		...		#some code

		pour savoir si la piece est une piece vide"""
		return False

	def __repr__(self):
		return f"Piece Vide {self.coord}"

	@property
	def couleur(self):
		raise TypeError("Une Piece Vide n'a pas de couleur")

	def __hash__(self):
		return hash((self.coordonnes,self.type))


class Pion(Piece):
	"""Difference : On fait une promotion si besoin"""
	def mvt(self,coord):
		t = super().mvt(coord)
		if self.coordonnes[0] == 8 or self.coordonnes[0] == 1:
			self.promotion()
		return t

	def promotion(self):
		"""Si le joueur est une IA : la pièce se transforme en Reine.
		Si c'est un joueur : pas encore implémenté"""
		if self.joueur.type == 'IA':
			self.__class__ = Reine
		else:
			pass #TODO

	def _calcul_mvt(self):
		cdef int y
		cdef int x
		y,x = self.coordonnes
		cdef int y1
		cdef Echiquier echiquier = self.echiquier
		y1 = y+1 if self.joueur.couleur else y-1
		piece = echiquier[y1][x]
		if not piece:
			yield (self,piece)

		if x <=7:
			piece = echiquier.get(y1,x+1)
			if piece and piece.joueur is not self.joueur:
				yield (self,piece)
		if x >=2:
			piece = echiquier.get(y1,x-1)
			if piece and piece.joueur is not self.joueur:
				yield (self,piece)

		if self.joueur.couleur and y == 2:
			piece = echiquier.get(y+2,x)
			piece_en_chemin = echiquier.get(y1,x)
			if not piece and not piece_en_chemin:
				yield (self,piece)
		elif not self.joueur.couleur and y == 7:
			piece_en_chemin = echiquier.get(y1, x)
			piece = echiquier.get(y-2,x)
			if not piece and not piece_en_chemin:
				yield (self,piece)





class Tour(Piece):
	"""Différence : on regarde si y'a déjà eu  un mouvement (pour le rock)"""
	def __init__(self,*args,**kwargs):
		super().__init__(*args,**kwargs)
		self.deja_bouger = False

	def mvt(self,coord):
		self.deja_bouger = True
		return super().mvt(coord)
		


	def _calcul_mvt(self):
		y,x = self.coordonnes
		cdef Echiquier echiquier = self.echiquier
		y1 = y+1
		piece = 0
		while not piece and y1<=8:
			piece = echiquier.get(y1,x)
			if piece.joueur is not self.joueur:
				yield((self,piece))
			y1+=1
		y1=y-1
		piece = 0
		while not piece and y1>=1:
			piece = echiquier.get(y1,x)
			if piece.joueur is not self.joueur:
				yield((self,piece))
			y1 -=1
		x1  = x+1
		piece = 0
		while not piece and x1<=8:
			piece = echiquier.get(y,x1)
			if piece.joueur is not self.joueur:
				yield((self,piece))
			x1+=1
		x1 = x-1
		piece = 0
		while not piece and x1>=1:
			piece = echiquier.get(y,x1)
			if piece.joueur is not self.joueur:
				yield((self,piece))
			x1-=1



class Fou(Piece):
	"""Pas de difs"""
	def _calcul_mvt(self):
		cdef int y,x,x1,y1,i,j
		cdef Echiquier echiquier = self.echiquier
		y,x = self.coordonnes
		y1 = y+1
		x1 = x+1
		piece = 0
		for i in range(-1,2,2):
			for j in range(-1,2,2):
				x1 = x+j
				y1 = y+i
				piece = 0
				while not piece and y1>=1 and y1<=8 and x1>=1 and x1<=8:
					piece = echiquier.get(y1,x1)
					if piece.joueur is not self.joueur:
						yield (self,piece)
					x1+=j
					y1+=i
					

class Cavalier(Piece):
	"""Pas de difs"""

	def _calcul_mvt(self):
		y,x = self.coordonnes
		cdef Echiquier echiquier = self.echiquier
		for a in range(-2,3,4):
			for xx in range(-1,2,2):
				y1 = y + a
				x1 = x + xx
				if 1 <= y1 <= 8 and 1 <= x1 <= 8:
					piece = echiquier.get(y1,x1)
					if self.joueur is not piece.joueur:
						yield (self,piece)
				y1 = y + xx
				x1 = x + a
				if 1 <= y1 <= 8 and 1 <= x1 <= 8:
					piece = echiquier.get(y1,x1)
					if self.joueur is not piece.joueur:
						yield (self,piece)

class Reine(Piece):
	"""Pas de difs"""

	def _calcul_mvt(self):
		cdef int y
		cdef int x
		cdef int xx
		cdef int yy
		y,x = self.coordonnes
		cdef Echiquier echiquier = self.echiquier
		for yy in range(-1,2):
			for xx in range(-1,2):
				if xx or yy:
					y1 = y+ yy
					x1 = x + xx
					piece = 0
					while not piece and x1 >=1 and x1<=8 and y1>=1 and y1<=8:
						piece = echiquier.get(y1,x1)
						if piece.joueur is not self.joueur:
							yield (self,piece)
						x1+=xx
						y1+=yy


class Roi(Piece):
	"""Echec, on regarde si la pièce à bouger"""
	def __init__(self,*args,**kwargs):
		super().__init__(*args,**kwargs)
		self.deja_bouger = False

	def mvt(self, coord):
		self.deja_bouger = True
		return super().mvt(coord)
		
                        

	def _calcul_mvt(self,echec=True):
		cdef int y,x,yy,xx
		y,x = self.coordonnes
		cdef Echiquier echiquier = self.echiquier
		for yy in range(-1,2):  
			for xx in range(-1,2):
				if xx or yy:    
					x1 = x+xx   
					y1 = y+yy   
					if y1>=1 and y1<=8 and x1>=1 and x1<=8: 
						piece = echiquier.get(y1,x1)
						if self.joueur is not piece.joueur: 
							yield ((self,piece))






LIGNE_PIECE_FOND = [None,Tour,Cavalier,Fou,Reine,Roi,Fou,Cavalier,Tour]
LIGNE_PION = [None]+[Pion]*8
TYPE_PIECE = {Pion:'pion',Tour:'tour',Cavalier:'cavalier',Roi:'roi',Reine:'reine',Fou:'fou'}
VALEUR_PIECE = {Pion:1,Tour:5,Cavalier:3,Fou:3,Reine:9,Roi:0}



def echec_roi(Echiquier echiquier,couleur):
	"""On veut savoir si le joueur est en échec au Roi"""
	for piece in echiquier.get_piece_by_couleur(not couleur):
		for _,cible in piece.liste_mvt():
			if isinstance(cible,Roi):
				return True
	return False


def echec_mat(echiquier,couleur):
	"""Renvoie 'True' si le joueur est en pat. Il n'y a échec et mat que si 'echec_roi' vaut 'True' aussi"""
	for piece in echiquier.get_piece_by_couleur(couleur):
		for piece,cible in piece.liste_mvt():
			not_echec = False
			temp = echiquier.temp_mvt(piece,cible)
			if not echec_roi(echiquier,couleur):
				not_echec = True
			echiquier.reset_mvt(temp)
			if not_echec:
				return False
				
	return True

