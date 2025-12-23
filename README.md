# gd-spelunker

A Godot-based sidescrolling procedurally generated platformer

![sample screenshot](screenshot.png)

## Quick Start

Install Godot 4.5 on macOS, clone this repo, and run:
```
/Applications/Godot.app/Contents/MacOS/Godot res://main.tcsn
```

## Gameplay

This is a 2D side-scroller with infinite-generating terrain with some exploration
vibe comparable to Terraria, except no crafting and not much variety of tools.

Controls are WASD mainly for the A, D keys for left and right movement, but N, M
where M is the jump button and N is the attack (swing sword) button. Holding
W and hitting N swings the sword up, holding S and hitting N swings the sword down.

The user can double-jump, and also by pushing against a wall can slide down it,
and while sliding down can jump off the wall similar to Mega Man X.

Terrain is procedurallly generated and contains areas of blue skies, underground
caves, and areas of water in both (in water, the user uses the M button to swim
like Mario in Super Mario Bros, instead of being able to jump there).

There are a variety of enemies including dumb walking enemies, bouncing enemies
like paratroopas in Super Mario Bros, Hammer Bros-like enemis throwing balls
in an arc pattern, and flying-horizontally enemies.

The user starts with 10 hearts of life, and loses one + flinches whenever hit
by enemies. Killing enemies with the sword often drops hearts that can be used
to recover life.

A score is shown, and the user earns points often for killing enemies. The main
objective is exploration so always display the X and Y coordinate. Anytime the
user reaches a further out 100x100 area (compared to the starting point at 0, 0)
in terms of max manhattan distance, highlight the achievement "grid exploration level"
increased, and award points.

## Visuals

The world should be colorful with daylight colors for the over-ground areas and
more cave-themed colors for the underground areas. There should render some background
elements of foothills and trees and scroll at a different speed to give a feeling
of parallax like in Super Mario world. The underground areas contain more stalagmites
and stalagtites as background areas.
