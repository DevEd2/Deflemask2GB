; Variables
IF	!DEF(VARS_INC)
VARS_INC	SET	1

SECTION	"Variables",BSS
GBCFlag			ds	1
GBAFlag			ds	1
SoundEnabled		ds	1
sys_ctrlBuffer		ds	1
sys_ctrlBuffer2		ds	1
sys_btnPressed		ds	1

ENDC