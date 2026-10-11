signal robotmove(mvntarr: Array)

enum direction {
	IDL,
	N,
	E,
	S,
	W
}

var dirstr = ["idle","N","E","S","W"]

enum actionType {
	PLANT_SEED,
	HARVEST_CROP,
	DELETE_CROP,
	WATER_CROP,
	FERTILIZE_SOIL
}

enum crops {
	EMPTY,
	WHEAT,
	TOMATO
}