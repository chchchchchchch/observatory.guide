pdf:
	./lib/mdsh/mk.sh E/tgsoguide.mdsh pdf

html:
	./lib/mdsh/mk.sh E/tgsoguide.mdsh html


lokal:
	./utils/lokalize.sh
#clean:
#	./utils/cleansvg.sh
images:
	./utils/xmpizeimgs.sh

