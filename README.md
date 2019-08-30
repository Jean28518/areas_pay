# Minetest Mod: Areas Pay
With this mod you can rent and buy areas in minetest.

## Required Mods:
- Areas Mod: https://github.com/minetest-mods/areas
- Jeans Economy: https://github.com/Jean28518/jeans_economy
- WorldEdit: https://github.com/Uberi/Minetest-WorldEdit

This mod doenst change any behavior of some of the above mods.

## Features:
- Rent Areas for a specific amount of time very fast and uncomplicated
- Areas can only rented 2 periods in the future by an customer (Can be configured easy)
- Sell Areas very easy
- After a rented Area becomes available again, Chests, LockedDoors, etc. are automaticly removed

## How to use:
- Just craft the Area Shop Block like the crafting recipe in the following Screenshots.
- Place the Block next to your specific Area, or in to it. In both cases only you can destroy it.
### Sell your Area:
- Rightclick, it and you get the Owner View. Fill in your Areas ID, and the Price. (The Period in Days Field can be ingored).
- After that click the "Save Fields" Button, to save your Configuration. After that any Player with enough money can buy your Area.
- When a Player buys the Area, the Block destroys itself after.
### Rent your Area:
- Rightclick, it and you get the Owner View. Fill in your Areas ID the Price, and the Period in Days. *So For Example: You rent the Area 2 for 1000 per 7 Days. By default a player can then rent the Area 2 Times (so for 14 Days) in beforehand.*
- After that click the "Save Fields" Button, to save your Configuration.
- With the click on the "Rent" or "Sell" Button (The last one) you change the Mode. If the Button shows "Rent", the Block is in rent mode.
- You can Destroy the Block whenever you want, even, if the area is rented. The only effect is, that the Customer cannot rent the area a period further on. The rent itself is handled by the mod database.
- You can also rent your area for one customer at the same time.
- **When you destroy your Area when someone is renting, the renting protection goes lost too. Changing your areas position while the area is rented is supported too, if the area belongs to you, and the area has the same ID.**

## Configuration:
In the init.lua file you are able to add more blocks, which should be removed after an area becomes available again. It is the variable ```BLOCKS_TO_REMOVE```. You can empty this table, if you want to deactivate this feature.

Also you can change the update time of the mod. It is the Period, in it every rented area is been checked, if it is valid. With ```MAX_RENT_PERIODS``` you can define, how many periods the customer can buy at once.

## Screenshots:
### Example Plot:
![Pic1](screenshot1.png)

### Owner View:
![Pic2](screenshot2.png)

### Customer View:
![Pic3](screenshot3.png)

### These Items will be automaticly removed after the rent time is up:
![Pic5](screenshot5.png)


### Crafting Recipe:
![Pic4](screenshot4.png)
