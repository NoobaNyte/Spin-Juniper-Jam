class_name LevelSequence
extends Resource

@export var level_name: String
@export var startup_commands: LevelStartupCommands
@export var commands: Array[BaseLevelCommand] # any subclass can go here