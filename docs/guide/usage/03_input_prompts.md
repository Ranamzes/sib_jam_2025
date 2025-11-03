---
layout: page
title: "Input prompts"
permalink: /usage/input-prompts
description: "How to display input prompts to the player."
---

## Introduction

Input prompts like "press A to jump" tell your player how to control your game while being in the game. Showing input prompts is a great usability feature which will make it easy for your players to understand how to play your game. Therefore G.U.I.D.E provides a way to display input prompts in your game based on your configured actions.

G.U.I.D.E itself does not mandate a specific way to display input prompts. Instead, you can use the built-in `GUIDEInputFormatter` class to build an input prompt string for any given action. You can then display this string in your game's user interface in any way you like. `GUIDEInputFormatter` can generate two kinds of input prompt strings:

- Pure text strings, which are suitable for displaying input prompts as text.
- Rich text strings, which are suitable for displaying input prompts as icons. These are intended to be used with Godot's `RichTextLabel` control.


## General setup

Before you can get strings from `GUIDEInputFormatter`, you first need to get an instance of the `GUIDEInputFormatter` class.  There are two ways to do this:

- You can get an instance of `GUIDEInputFormatter` with the `GUIDEInputFormatter.for_active_contexts()` factory method. This will return a formatter that will use the action mappings of all currently active mapping contexts. It will automatically keep track of changes to the active contexts, so you don't need to worry about updating the formatter when the active contexts change.
- You can also create a formatter for a specific mapping context by calling `GUIDEInputFormatter.for_context(context)`. This will create a formatter that uses the action mappings of the specified context. This is mainly useful if you want to display input prompts in a key binding dialog where you want to show the prompts for a specific context.

## Getting input prompt strings

Once you have an instance of `GUIDEInputFormatter`, you can use it to get input prompt strings for your actions. The `GUIDEInputFormatter` class provides multiple different methods to get input prompt strings. The simplest one is `action_as_text` which returns a text string for a given action

```gdscript

# The action for which we want to get the input prompt. 
@export var jump_action:GUIDEAction

# The formatter that we will use to get the input prompt string.
var _formatter:GUIDEInputFormatter = GUIDEInputFormatter.for_active_contexts()

# An example function that updates a label with the input prompt string for the jump action.
func update_prompt_label():
    var action_text:String = _formatter.action_as_text(jump_action)

    $Label.text = tr("%s to jump") % [action_text]
```

The returned text will be a human-readable string that describes the input for the given action. For example, if the action is mapped to the `A` button on an XBox gamepad, the returned string will be `A`. If the action is mapped to the `Space` key on the keyboard, the returned string will be `[Space]`. The returned string will automatically reflect the actual input device being currently used, so you don't need to worry about displaying the correct input prompt for the player's input device. 

Note, that the returned string may contain more than one input, if an action is mapped to multiple inputs. For example if an action is mapped to the _W_, _S_, _A_, and _D_ keys on the keyboard, the returned string will be `[W], [S], [A], [D]`. Similar if the mapping is using a combo modifier, the returned string will be the combo, e.g. `A > B > A > X > Y`. If the action is mapped using chorded input, the returned string will be the chord, e.g. `LT + A`.

Also note, that the returned string will not contain a description of the action itself, only the input prompt. This is why in the example above we add the action description manually. `GUIDEInputFormatter` will automatically feed the input description through Godot's `tr` function so you can properly localize the prompt if desired.

### Rich text strings

If you want to display input prompts as icons, you can use the `action_as_richtext_async` method. This method returns a BBCode string that can be directly fed into Godot's `RichTextLabel` control. It is important to know that the `GUIDEInputFormatter` will create these icons on the fly because there is quite a big amount of potential icons to be made (e.g. keyboard keys have labels in all kinds of different languages, so creating all possible icons beforehand really is not feasible). This means that this method may not return immediately but may take a frame or two to complete. You must therefore call this method asynchronously and update the `RichTextLabel` when the string is ready. Here is an example of how to use this method:

```gdscript

func update_prompt_label():
    # Note that we use `await` here to wait for the result of the async method.
    var action_text:String = await _formatter.action_as_richtext_async(jump_action)


    $RichTextLabel.parse_bbcode(tr("%s to [b]jump[/b]") % [action_text])

```

## Keeping the input prompt up-to-date

When mapping contexts change, the player re-binds an input or joypads get connected and disconnected you will need to update the input prompt strings. G.U.I.D.E provides a signal to which your UI can subscribe to get notified when the input prompt strings need to be updated:


```gdscript
func _ready():
    # Subscribe to the input_mappings_changed signal to get notified when the input mappings change.
    GUIDE.input_mappings_changed.connect(_on_input_mappings_changed)

func _on_input_mappings_changed():
    # Update the prompt labels with the new input prompt strings.
    ...
```


## An example implementation

All examples that come with G.U.I.D.E use a shared `RichTextLabel` to display the input prompts. This label has an `instructions_text` property that describes the actions that the player can perform. In a second `actions` property, the actual `GUIDEAction` objects are stored. 

![Input prompt label]({{site.baseurl}}/assets/img/manual/manual_instructions_label.png)


At runtime, the label will use the `GUIDEInputFormatter` to generate the input prompt strings for these actions and display them in the label. 


![Input prompt label in game]({{site.baseurl}}/assets/img/manual/manual_instructions_label_runtime.png)


The label will automatically update the input prompt strings when the input mappings change. This is not the only way to display input prompts, but it is a simple and effective way to do so and you can easily adapt it to your needs or use it as a starting point for your own implementation. You can find the full implementation of the input prompt label in the example projects that come with G.U.I.D.E at `guide_examples/shared/instructions_label.gd`. 