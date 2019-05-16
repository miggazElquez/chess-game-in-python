from .graphique import main


if __debug__:
	import cProfile
	import pstats
	cProfile.run('main()','x')
	stats = pstats.Stats('x')
	stats.strip_dirs().sort_stats('time').print_stats()
else:
	main()