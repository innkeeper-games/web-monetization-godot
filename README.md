# How to Monetize a Godot Game with Web Monetization
Web Monetization is a new way to monetize web games (and any other web content). It's a protocol that allows for quick transfers of money. Users can sign up through a Web Monetization provider (like [Coil](https://coil.com)) to gain access all Web Monetized content, and creators of that content get paid based on the amount of time users spend on their sites.

We can use Web Monetization to earn money from web exported games made with Godot. We can even check if the user is paying and offer them exclusive content if they are! This tutorial offers three different approaches to monetizing your web game using Godot and Web Monetization (WM).



Check out the demo [here](https://innkeeper-games.github.io/web-monetization-godot/) and the (MIT licensed) source code [here](https://github.com/innkeeper-games/web-monetization-godot).

<!--more-->

## Just Monetize the Game
The simplest step is to alert the WM provider that the game is monetized and give it a pointer to send money to. In general, we do this by adding a `meta` tag to the `<head>` section of our HTML document. Here's the one included in the demo:

`<meta name="monetization" content="$ilp.uphold.com/ghyDriDrafqi" />`

The meta tags include the name "monetization" and the content of your payment pointer. Without a payment pointer, the WM provider won't know where to send money, so you'll need to get your hands on one of these to monetize your game. Check out [this page](https://help.coil.com/accounts/digital-wallets-payment-pointers) to learn how to grab one.

Once you have your payment pointer, open your Godot project and navigate to `Project -> Export...`. This will open the window to export your game. If you haven't already added HTML5 to your list of exports, add it by pressing `Add... -> HTML5`.

Then, in the `Options` tab, add your meta tag (including your payment pointer) under `Head Include` to include the tag in the exported game's `<head>` section. After you've done that, you'll already be ready to start earning money! WM-enabled users of your web exported Godot game will stream money to your payment pointer while they play. The rest of this tutorial covers how to detect Web Monetization and offer exclusive content to those with Web Monetization enabled in Godot.

![](head-include.png)

## Check if a User has Web Monetization Enabled in Godot
Web Monetization has a helpful [JavaScript API](https://webmonetization.org/docs/api) that lets us check whether the user's browser knows about Web Monetization, and, if it does, lets us check the `state` of monetization (namely, whether the user's payment is `stopped`, `pending`, or `started`). In this case, if it's `started`, we'll offer exclusive content.

For this tutorial, we'll be focused on whether the user has a WM provider and whether they're actively streaming money. Thankfully, Godot offers its [`JavaScript`](https://docs.godotengine.org/en/3.2/classes/class_javascript.html) singleton that allows us to interact with the browser by accessing its JavaScript context. We can directly use its `eval` method to evaluate JavaScript and get a return value. Through this singleton, we can use the Web Monetization JavaScript API.

First, create a new script called `WebMonetization.gd` that extends `Node`. We'll `AutoLoad` this script so it's accessible as a singleton from anywhere in our game. Go to `Project -> Project Settings...` and then navigate to the `AutoLoad` tab. Add the path of your script and press `Add`. The name appearing in the `Name` column is how you'll call functions from anywhere in the project (i.e. using `WebMonetization.<function>`).

Let's add some code to our singleton that checks whether the user's browser supports Web Monetization, and then, if it does, starts keeping track of whether the user is paying.

As soon as our game loads, we want to know whether the user's browser supports WM, so We'll start by adding some code to our `WebMonetization` singleton's `_ready` function that performs the check.

First, add a `poll` timer node and a `paying` boolean to our singleton's member fields.

```
var _paying: bool
var _poll: Timer
```

Then, using the `JavaScript` class's `eval` method, we can check if the `document.monetization` property exists, i.e. if the user's browser supports WM. If it does, we can create timer and `connect` it to another method we write, so each time the timer runs out, our method is executed (we'll cover signals more in-depth when we talk about exclusive content). This allows us to repeatedly check whether monetization is started. (If you only care about the first time monetization starts and don't care to check repeatedly, you can add the commented line to free the timer node at that point.)

```
func _ready() -> void:
	if JavaScript.eval("(document.monetization !== null);"):
		_poll = Timer.new()
		add_child(_poll)
		_poll.connect("timeout", self, "_on_poll_timeout")
		_poll.one_shot = false
		_poll.start(1)
```

```
func _on_poll_timeout() -> void:
	if JavaScript.eval("(document.monetization.state === 'started');"):
		if not _paying:
			_paying = true
			#_poll.queue_free()
	elif _paying:
		_paying = false
```

Now, we can write a method, accessible from anywhere in the project, called `is_paying` that returns our whether the user is currently paying.

```
func is_paying() -> bool:
	return _paying
```

## Offering Exclusive Content to Web Monetized Users
Here are two useful ways to act on whether a user has WM enabled and offer them exclusive content if they do.

### Using Our `is_paying` Method
This is how the gate works in the demo. When the player `KinematicBody2D` enters the gate's `Area2D`, the gate checks whether the user is paying using `WebMonetization.is_paying()`. If the method returns `True`, we open the gate and disable the gate's collision so the user can pass through.

(`Left` and `Right` are the `AnimatedSprite`s corresponding to the left and right sides of the gate, respectively.)

```
func _on_Area2D_body_entered(body: CollisionObject2D):
	if body is KinematicBody2D and WebMonetization.is_paying():
		$Opening/CollisionShape2D.set_deferred("disabled", true)
		$Left.play("open")
		$Right.play("open")


func _on_Area2D_body_exited(body: CollisionObject2D):
	if body is KinematicBody2D and WebMonetization.is_paying():
		$Opening/CollisionShape2D.set_deferred("disabled", false)
		$Left.play("close")
		$Right.play("close")
```

We use `set_deferred()` here to ensure that the collision shape is disabled when it's safe to (after the current frame's physics step has finished).

### Using Godot's Signals
For content that needs to change as soon as payment starts, we can use Godot's Signals, analogous to the [observer pattern](https://en.wikipedia.org/wiki/Observer_pattern) in software design. Essentially, objects in Godot can `emit` signals, like a signal for when monetization starts, and other objects can `connect` those signals to their own methods, so that whenever those signals are emitted, their own methods are called. It's like a subscription. This is how the sign's popup works in the demo.

First, we need to declare the signals for when monetization starts and stops. We'll do this near the member fields we've already declared in the `WebMonetization` singleton.

```
signal on_monetization_started
signal on_monetization_stopped
```
Now, we need to actually `emit` this signals when their corresponding events occur. Since we already have a method, `_on_poll_timeout`, called regularly that checks if the user is paying, we can do this from that method.

```
func _on_poll_timeout() -> void:
	if JavaScript.eval("(document.monetization.state === 'started');"):
		if not _paying:
			emit_signal("on_monetization_started")
			_paying = true
			#_poll.queue_free()
	elif _paying:
		_paying = false
		emit_signal("on_monetization_stopped")
```

Now, when the gate is ready, we `connect` the `WebMonetization` singleton's `on_monetization_started` signal to a method belonging to `self` which we'll then write, `_on_monetization_started()`.

```
func _ready() -> void:
	WebMonetization.connect("on_monetization_started", self, "_on_monetization_started")
```

Our `_on_monetization_started()` method should enable our exclusive content, since it's connected to the signal emitted when the user starts paying. In this case, we're changing the text on the sign's popup to thank the user.

```
func _on_monetization_started() -> void:
	$PanelContainer/Label.text = """Thanks for supporting our
	work with Web Monetization!"""
```

If you'd like, you can follow a similar approach to change the content back when monetization stops.

That's it! In this tutorial, we've covered how to detect if a user's browser supports Web Monetization in the Godot Game Engine, and, if it does, two ways to act on that and offer exclusive content.

I'd love any feedback you might have! Feel free to email `contact@innkeepergames.com` or create an issue or PR on the [GitHub repo](). Thanks!

Innkeeper Games is a one-person indie game studio making warm games about community while creating educational resources for game developers. If you're interested in more tutorials and game development content from Innkeeper Games, [follow me on Twitter](https://twitter.com/innkeeper_games) and subscribe to get new posts directly in your inbox.

<!--emailsub-->
<div id="toc"></div>

## Godot Engine License
This demo uses Godot Engine, available under the following license:

Copyright (c) 2007-2020 Juan Linietsky, Ariel Manzur. Copyright (c) 2014-2020 Godot Engine contributors.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.