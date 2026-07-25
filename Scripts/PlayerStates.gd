extends Node

enum playerState
{
	FALLING,
	RUNNING,
	IDLE,
	WALLRUNNING,
	JUMPING,
	WALLSLIDE,
	WALLJUMPING,
	SLIDING,
	ROLLING
}

var currentState = playerState.IDLE

func change_state(newState):
	currentState = newState
