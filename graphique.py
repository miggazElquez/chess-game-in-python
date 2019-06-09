import math
import argparse

import pygame as pg
from path import Path

from .classe import *
from . import classe




def case_clicked(pos):
	"""Donne les coordonnes de la case sur laquelle on clique.
	/!\\ Les coordonnées sont donnés dans le graphique : 

	|1,1|2,1|3,1|...
	|1,2|2,2|3,2|...

	"""
	x = pos[0]//100+1
	y = pos[1]//100+1

	if (x,y) > (8,8):

		return None,None

	return x,y


def coord_coin_case(x,y):
	"""
	Donne les coordonnes du coin en haut à gauche de la case (y,x) [coordones graphiques].
	Si on veut afficher une image de dimension (100,100) sur la case du graphique (2,3), il faut l'afficher aux coordonnes ()
	(1,1) va donc donner (0,0) par exemple, (2,2) va donner (100,100).
	|0,0  |100,0  |200,0  |...
	|0,100|100,100|200,100|...
	"""
	x = (x-1)*100	
	y = (y-1)*100
	return x,y



def conversion_case_graphique_jeu(x,y):
	"""
	On donne les coordonnes des cases dans le graphique, et on renvoie les coordonnes des case correspondantes dans le jeu.
	Graphique : 

	|1,1|2,1|3,1|...
	|1,2|2,2|3,2|...
	...

	Dans le jeu:

	|[8][1]|[8][2]|[8][3]|...
	|[7][1]|[7][2]|[7][3]|...
	...

	On renvoit dans l'ordre inverse !!! (on garde (x,y) même si dans le jeu on utilise (y,x),la conversion est à faire après)
	"""
	x1 = x
	y1 = 9-y
	return x1,y1

def conversion_case_jeu_graphique(x,y):
	"""L'inverse de la précédente : on prend une case dans le jeu,et on donne ses coords pour le graphique"""
	return x,9-y



def affich_echiquier(echiquier):
	for piece in echiquier:
		if piece:
			nom = piece.type + '-' + piece.couleur
			y,x = piece.coordonnes
			x_graph, y_graph = conversion_case_jeu_graphique(x,y)
			x_blit, y_blit = coord_coin_case(x_graph,y_graph)
			fenetre.blit(IMAGE_PIECES[nom],(x_blit+14,y_blit))

def affich_mvt(piece):
	for init,cible in piece.liste_mvt(echec_non_compris=True):
		y,x = cible.coordonnes
		x_graph, y_graph = conversion_case_jeu_graphique(x,y)
		x_blit, y_blit = coord_coin_case(x_graph,y_graph)

		#echiquier_bis = echiquier.copie()
		#Je sais plus pk ces deux lignes sont là... enfin bon, je les laisse
		#init.equiv_autre_echiquier(echiquier_bis) >> cible.equiv_autre_echiquier(echiquier_bis)
		if cible:
			fenetre.blit(DATA.marqueur_rouge,(x_blit,y_blit))
		else:
			fenetre.blit(DATA.marqueur_bleu,(x_blit,y_blit))


def flip(echiquier):
	fenetre.blit(DATA.echiquier_image,DATA.pos_echiquier)
	affich_echiquier(echiquier)
	pg.display.flip()




def choisir_piece(event,echiquier):
	x,y = case_clicked(event.pos)
	if (x,y) == (None,None):
		return None
	x_jeu, y_jeu = conversion_case_graphique_jeu(x,y)
	piece = echiquier[y_jeu][x_jeu]
	return piece







class JeuNormal:
	"""Classe servant à gérer l'interaction dans le cas d'une phase de jeu normale"""

	def __init__(self,joueurs,first=0):
		self.joueurs = joueurs
		self.joueur_en_cours = joueurs[first]
		self.selection = False
		self.affich_mvt = False
		self.play_IA = False

	def react_event(self,event):
		if event.type == pg.MOUSEBUTTONDOWN:
			piece_cible = choisir_piece(event,echiquier)
			if piece_cible is None:
				return False
			if self.affich_mvt:
				for _,cible in self.piece_selected.liste_mvt(echec_non_compris=True):
					if cible is piece_cible:
						self.piece_selected >> piece_cible
						self.joueur_en_cours = self.joueurs[not(self.joueurs.index(self.joueur_en_cours))] #On change de joueur
						self.affich_mvt = False
						return True

			if piece_cible.joueur is self.joueur_en_cours: #Si il y a eu mouvement, ça s'arrête avant.
				self.affich_mvt = True
				self.piece_selected = piece_cible
				return True
			return False

	def flip(self):
		fenetre.blit(DATA.echiquier_image,DATA.pos_echiquier)
		if echec_roi(echiquier,self.joueur_en_cours.couleur):
			for piece in echiquier:
				if isinstance(piece,Roi) and piece.joueur is self.joueur_en_cours:
					y,x = piece.coordonnes
			x_blit,y_blit = coord_coin_case(*conversion_case_jeu_graphique(x,y))
			fenetre.blit(DATA.marqueur_noir,(x_blit,y_blit))
		if self.affich_mvt:
			affich_mvt(self.piece_selected)
		affich_echiquier(echiquier)
		pg.display.flip()


	def normal_fonctionnement(self):
		if self.joueur_en_cours.type=="IA":
			mvt = IA_decision(echiquier,self.joueur_en_cours,init_barre_cote,en_cours_barre_cote,end_barre_cote)
			mvt[0] >> mvt[1]
			self.joueur_en_cours = self.joueurs[not(self.joueurs.index(self.joueur_en_cours))] #On change de joueur
			return True

		return False


def init_barre_cote(max_):
	rect = pg.Rect(800,0,100,800)
	pg.draw.rect(fenetre,(255,255,255),rect)
	pg.draw.rect(fenetre,(0,0,0),rect,5)
	pg.display.flip()

def en_cours_barre_cote(i,max_):
	taille_case = math.ceil(800/max_)
	rect = pg.Rect(800,i*taille_case,100,taille_case)
	pg.draw.rect(fenetre,(50,205,50),rect)
	pg.draw.rect(fenetre,(0,0,0),(800,0,100,800),5)
	pg.event.clear()
	pg.display.flip()

def end_barre_cote(max_):
	rect = pg.Rect(800,0,100,800)
	pg.draw.rect(fenetre,(160,82,45),rect)
	pg.draw.rect(fenetre,(0,0,0),rect,5)
	pg.display.flip()
	



class DATA:
	"""Classe qui ne sert qu'à stocker les différentes images"""
	pass


def main():

	parser = argparse.ArgumentParser("Chess")
	parser.add_argument('--multi', type=int, default=-1, help="Number of process to use for the IA. Value of 0 mean no multiprocessing, value of -1 mean default")

	args = parser.parse_args()
	if args.multi !=-1:
		if args.multi == 0:
			classe.MULTI = False
		else:
			classe.NB = args.multi





	path = Path(__file__).parent/"data"/"images"

	pg.init()


	global fenetre
	fenetre = pg.display.set_mode((900,800),pg.FULLSCREEN)

	#font = pg.font.Font(None,50)

	DATA.echiquier_image = pg.image.load(path/"echiquier1.png").convert()
	DATA.pos_echiquier = DATA.echiquier_image.get_rect()


	DATA.marqueur_bleu = pg.image.load(path/'marqueur_bleu.png').convert()
	DATA.marqueur_bleu.set_colorkey((255,255,255))
	DATA.marqueur_rouge = pg.image.load(path/'marqueur_rouge.png').convert()
	DATA.marqueur_rouge.set_colorkey((255,255,255))
	DATA.marqueur_noir = pg.image.load(path/'marqueur_noir.png').convert()
	DATA.marqueur_noir.set_colorkey((255,255,255))

	global IMAGE_PIECES
	IMAGE_PIECES = {}
	for i in ('pion','cavalier','tour','roi','reine','fou'):
		for j in ('blanc','noir'):
			nom = i+'-'+j
			IMAGE_PIECES[nom] = pg.image.load(path/(nom+'.jpg')).convert()

	for images in IMAGE_PIECES.values():
		images.set_colorkey((255,255,255))


	global j1,j2,echiquier

	j1,j2,echiquier = init()
	fenetre.blit(DATA.echiquier_image,DATA.pos_echiquier)
	affich_echiquier(echiquier)
	pg.display.flip()


	tour_en_cours = [1,0,0]
	JOUEURS = [[j1,1],[j2,0]]
	joueur_en_cours = JOUEURS[0]
	piece = None


	phase_en_cours = JeuNormal((j1,j2))

	continuer = True
	while continuer:
		for event in pg.event.get():
			if event.type == pg.KEYDOWN and event.key == pg.K_ESCAPE:
				pg.display.iconify()
			elif event.type == pg.KEYDOWN or event.type == pg.QUIT:
				continuer = False
			if phase_en_cours.react_event(event):
				phase_en_cours.flip()
			if phase_en_cours.normal_fonctionnement():
				phase_en_cours.flip()

	pg.quit()






if __name__ == '__main__':
	#Je le laisse mais vaut mieux utiliser le '__main__.py'
	if __debug__:
		import cProfile
		import pstats
		cProfile.run('main()','x')
		stats = pstats.Stats('x')
		stats.strip_dirs().sort_stats('time').print_stats()
	else:
		main()
	