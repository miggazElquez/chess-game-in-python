"""Diverses fonctions utiles pour debug"""
from termcolor import cprint
from .classe import *
import echec.classe as classe

def assert_liste_piece_is_ok(echiquier):
	t_1,t_2 = [],[]
	for piece in echiquier:
		if piece.joueur is echiquier.j1:
			t_1.append(piece)
		elif piece.joueur is echiquier.j2:
			t_2.append(piece)
	if set(t_1) != echiquier.piece_j1:
		t = set(t_1)^echiquier.piece_j1
		for i in t:
			print(i, 'pas dans liste' if i in t_1 else 'pas dans plateau')
		raise Exception
	if set(t_2) != echiquier.piece_j2:
		t = set(t_2)^echiquier.piece_j2
		for i in t:
			print(i, 'pas dans liste' if i in t_2 else 'pas dans plateau')
		raise Exception





def affich_liste_mvt(liste):
	"""Affiche une liste de mouvement de façon lisible"""
	for piece,cible in liste:
		if cible:
			cprint(repr(piece) + ' >> ' + repr(cible),'green',attrs=['bold'])
		else:
			cprint(repr(piece) + ' >> ' + repr(cible),'green')


def min_DEBUG(echiquier,joueur,profondeur,val_min_possible,first_step=False):
	classe.X+=1
	print("\t"*(3-profondeur)+"Min : on check l'echiquier")
	print(echiquier.repr_indent(3-profondeur))
	if echec_mat(echiquier,joueur.couleur):
		return 1000
	if echec_mat(echiquier,not(joueur.couleur)):
		return -1000

	if not profondeur:
		return echiquier.get_value(joueur)

	val_min = 1001

	for piece in echiquier.get_piece_by_couleur(not joueur.couleur):
		for piece,cible in piece.liste_mvt():
			temp = echiquier.temp_mvt(piece,cible)
			if not echec_roi(echiquier,not joueur.couleur):
				score = max_DEBUG(echiquier,joueur,profondeur-1,val_min)
				if score < val_min:
					val_min = score
				print("\t"*(3-profondeur)+f"val_min = {val_min}")
			echiquier.reset_mvt(temp)
			if first_step:	#Dans le first step, on ne cherche pas la valeur la plus forte mais tout les coups qui ont cette valeur.
				if val_min < val_min_possible:	#On ne peut donc pas couper en cas d'égalité
					print("\t"*(3-profondeur)+f"we stop here because {val_min}<{val_min_possible}")
					return val_min
			else:
				if val_min <= val_min_possible:
					print("\t"*(3-profondeur)+f"we stop here because {val_min}<={val_min_possible}")
					classe.Y+=1
					return val_min 
	print("*"*50)
	return val_min



def max_DEBUG(echiquier,joueur,profondeur,val_max_possible):
	classe.X+=1
	print("\t"*(3-profondeur)+"Max : on check l'echiquier")
	print(echiquier.repr_indent(3-profondeur))
	if echec_mat(echiquier,joueur.couleur):
		return 1000
	if echec_mat(echiquier,not(joueur.couleur)):
		return -1000

	if not profondeur:
		return echiquier.get_value(joueur)
	val_max = -1001

	for piece in echiquier.get_piece_by_joueur(joueur):
		for piece,cible in piece.liste_mvt():
			temp = echiquier.temp_mvt(piece,cible)
			if not echec_roi(echiquier,joueur.couleur):
				score = min_DEBUG(echiquier,joueur,profondeur-1,val_max)
				if score > val_max:
					val_max = score
				print("\t"*(3-profondeur)+f"val_max = {val_max}")
			echiquier.reset_mvt(temp)
			if val_max >= val_max_possible:
				print("\t"*(3-profondeur)+f"we stop here because {val_max}>={val_max_possible}")
				classe.Y +=1
				return val_max
	print("*"*50)
	return val_max
