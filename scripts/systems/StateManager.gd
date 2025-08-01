extends Node

enum GameState
{
	MainMenu,
	Game,
	GameOver,
	Shop
}

enum StateChange
{
	Toggle,
	Enable,
	Disable
}

var gameStateCanChange: bool = true
var currentState: GameState = GameState.MainMenu

signal gameStateChanged(newGameState: GameState)

func ToggleGameStateAllowance(_state: StateChange):
	match _state:
		StateChange.Toggle:
			gameStateCanChange = !gameStateCanChange
		StateChange.Enable:
			gameStateCanChange = true
		StateChange.Disable:
			gameStateCanChange = false
		_:
			gameStateCanChange = !gameStateCanChange

func _changeGameState(_newGameState: GameState):
	if !gameStateCanChange:
		printt("Game State is locked, cannot be changed")
		return
	currentState = _newGameState
	gameStateChanged.emit(_newGameState)

func SetMainMenuState():
	_changeGameState(GameState.MainMenu)

func SetGameState():
	_changeGameState(GameState.Game)

func SetGameOverState():
	_changeGameState(GameState.GameOver)

func SetShopState():
	_changeGameState(GameState.Shop)
