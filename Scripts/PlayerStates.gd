extends Node

enum playerState
{
	FALLING,
	RUNNING,
	IDLE,
	WALLRUNNING,
	JUMPING,
	WALLSLIDE,
	WALLJUMPING
}

var currentState = playerState.IDLE

func change_state(newState):
	currentState = newState
