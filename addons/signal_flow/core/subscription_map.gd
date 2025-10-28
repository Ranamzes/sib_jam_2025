class_name SubscriptionMap
extends Resource

# An array of dictionaries, where each dictionary contains the information
# for a single subscription to be made at runtime.
# Example: [{"node_path": "Player", "event_name": "player_died", "method_name": "_on_player_died"}]
@export var subscriptions: Array = []
