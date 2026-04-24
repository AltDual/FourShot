# FourShot
by Taiki Shinokawa, Michael Chen, Braden Chiu

Built in 4 days for the 2026 SMCCCD Hackathon

<img width="1918" height="1076" alt="Screenshot 2026-04-24 013607" src="https://github.com/user-attachments/assets/ee68b441-fd73-48ec-9879-91a51c1c0b35" />

# About

## Inspiration
Inspired by the nostalgic flash games of our childhood like [Endless War 3](https://www.addictinggames.com/shooting/endless-war-3), we aimed to build a top-down 2d shooter that captured the strategical aspect we enjoyed while also containing modern progression systems, allowing the player to feel like they leveled up while playing. We were also inspired by the Hypixel Skyblock dungeon system, where fast players are rewarded for speeding straight to the boss room; at the same time, slow players can methodically clear every room of the procedurally generated dungeon for greater stat buffs.
## What it does
The game is a roguelike where the player navigates through a randomly generated dungeon. The player has an inventory and hotbar system where two weapons can be carried and used. While journeying through the dungeon, a map and minimap is provided, allowing the player to keep track of which rooms are visited and where the enemies are. Upon entering the rooms, the player must clear every enemy to unlock the doors, recover health, and gain XP. As players gain XP, they can level up, providing them a choice of stat buffs. The objective for now is to explore until you reach the boss room, then fight the golem boss using a special weapon.
## How we built it
We used Godot with Git version control. On the first day, we brainstormed on a shared document and then created task boards. In the following days, we had daily 3-5 hour sessions of collaboration and feature development. The scripting was AI-assisted. Most sprites are free and sourced online, with the rest being drawn in Aseprite and Libresprite. The music and sound effects were created in FL Studio. 
## Challenges we ran into
Firstly, we were all new to Godot, so we had to learn how to use it in the first place. Handling the procedural generation was a significant challenge; we had to tweak the dungeon generation system and ensure randomization of obstacles would not happen again when reentering a room. Another issue was balancing, since we struggled to balance difficulty with challenge. 
## Accomplishments that we're proud of
- We successfully built a procedural dungeon generation system that allows the player to explore a new dungeon every playthrough.
- We developed a scalable weapon system that allows new weapons to be created easily. The hotbar system is also very intuitive.
- The movement and dodging of the bullets is very satisfying to play, especially with the dash mechanic.
## What we learned
- Art is a significant time factor that we did not account for; creating assets takes a lot of time.
- TileMaps are a valuable tool because they allow for random generation while accomodating enemy pathfinding.
- A little bit of polish (like the explosions and muzzle flash) goes a long way.
- The importance of not overscoping! We initially planned a weapon progression system with weapon combos, but did not have enough time.
## What's next for FourShot
Due to the scalability of the weapon and enemy systems, it is easy to add more content. We had originally planned for weapons like a flamethrower, a fireball spell, and a shotgun. Other content to be added is long corridor rooms, more obstacles and structures in the rooms, and more visual effects. Even later in the future is a new floor with new enemies, weapons, and bosses, along with new starting characters/weapons. 

