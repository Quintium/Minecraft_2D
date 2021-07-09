// class for all the player actions
class Actions {
    // initialize targets
    Block target = null;
    PVector placeBlock = null;
    
    // initialize break and place cooldowns
    long lastUpdate = -1;
    long lastPlace = -1;
    long lastHit = -1;
    long lastDrop = -1;
    long eatingStart = -1;
    
    // initialize inventory
    Collection inventory = new Collection(3, 9);
    Collection hotbar = new Collection(1, 9);
    int select = 0;
    
    Actions() {
    }
    
    // return currently selected item
    Item selectedItem() {
        return hotbar.items[0][select];
    }
    
    // add item to inventory
    void addToInventory(Item item) {
        // try to add item to existing ones
        hotbar.add(item);
        inventory.add(item);
        
        // if failed fill collections with leftover
        hotbar.fill(item);
        inventory.fill(item);
    }
    
    void unbreak() {
        if (target != null) {
            target.timeBroken = -1;
            lastUpdate = -1;
        }
    }
    
    // set target and future block pos to null
    void untarget() {
        target = null;
        placeBlock = null;
    }
    
    // return if player has placed block in last 0.2 secs
    boolean getPlacing() {
        return game.time - lastPlace < 200 ? true : false;
    }
    
    // return if player is breaking block
    boolean getBreaking() {
        return lastUpdate != -1;
    }
    
    // return if food is being eaten
    boolean getEating() {
        return eatingStart != -1;   
    }
    
    // return if player is hitting
    boolean getHitting() {
        return game.time - lastHit < 200 ? true : false; 
    }
    
    // return if player is dropping item
    boolean getDropping() {
        return game.time - lastDrop < 200 ? true : false; 
    }
    
    boolean checkBlocked(Hitbox hitbox) {
        // check if hitbox is blocked by another block or mob (to avoid blocks being placed into each other)
        for (Chunk chunk : world.chunks) {
            // only check chunks near the block
            if (hitbox.overlap(chunk.outHitbox)) {
                // check blocks
                for (Block block : chunk.blocks) {
                    if (block.getHitbox().overlap(hitbox)) {
                        return true;
                    }
                }
                
                // check mobs
                for (Mob mob : chunk.mobs) {
                    // check if hitbox collides with mob
                    if (hitbox.overlap(mob.getHitbox())) {
                        return true;
                    }
                }
            }
        }
        
        // return true if hitbox overlaps with player
        return player.getHitbox().overlap(hitbox);
    }
    
    // find target
    void targetBlock() {      
        // calculate angle and distance to cursor
        float angle = player.direction();
        float distance = player.distance();

        // initialize variables, placeBlock is the future block when placed
        boolean changed = false;
        PVector previous = null;

        // check all distances between 0 and 4 that are smaller than distance to cursor
        for (float d = 0; d < 4.5 && !changed && d < distance; d += 0.03) {
            // calculate target pos based on angle, distance "d" and position of player
            PVector targetPos = PVector.mult(PVector.fromAngle(angle), d);
            targetPos.add(0.25, 0.5);
            targetPos.add(player.pos);
            Hitbox targetHitbox = new Hitbox(targetPos, 0);

            // check if targetPos is in any block
            for (Chunk chunk : world.chunks) {
                // only check chunks near the point
                if (targetHitbox.overlap(chunk.outHitbox)) {
                    for (Block block : chunk.blocks) {
                        if (block.getHitbox().overlap(targetHitbox)) {
                            // unbreak and set new target if a new target has been found
                            if (target != block) {
                                unbreak();
                                target = block;
                            }
                            
                            // set placeBlock to previous free position if it isn't blocked
                            if (previous != null) {
                                placeBlock = previous;   
                            }
                            
                            changed = true;
                        }
                    }
                }
            }
            
            // set previous to the top left corner of the block
            previous = new PVector(floor(targetPos.x), floor(targetPos.y));
        }

        // if the block has been untargeted, untarget and unbreak it
        if (!changed) {
            unbreak();
            untarget();
        }
    }

    void breaking() {
        if (target != null && target.hardness != -1) {
            if (leftMouse) {
                // check if block is being broken
                if (lastUpdate > -1) {
                    // calculate relative time passed since last update
                    float timePassed = (game.time - lastUpdate) / target.getBreakTime();
                    
                    if (target.timeBroken + timePassed < 1) {
                        // change the time broken by the time passed since last update
                        target.timeBroken += timePassed;
                        
                        // save last breaking update
                        lastUpdate = game.time;
                    } else {
                        // remove block
                        target.finish();
                        target.removeFromChunk();
                        
                        // decrease item durability
                        selectedItem().decreaseDurability();
                        
                        // drop all drops and save chunk
                        target.dropItems();
                        target.saveChunk();
                        
                        // untarget and reset breaking
                        untarget();
                        lastUpdate = -1;
                        
                        // increase player exhaustion
                        player.exhaustion += 0.005;
                    }
                } else {
                    // start breaking
                    target.timeBroken = 0;
                    lastUpdate = game.time;
                }
            } else {
                unbreak();
            }
        }
    }
    
    void leftClick() {
        // get direction and distance from player to cursor in coord space
        float dir = player.direction();
        float dist = player.distance();
        
        // while not finished
        boolean finished = false;
        
        // increase d from 0 to distance until it hits block or mob
        for (float d = 0; d < dist && !finished; d += 0.03) {
            // create pvector from angle dir and magnitude d and add to player head
            PVector targetPos = PVector.mult(PVector.fromAngle(dir), d);
            targetPos.add(0.25, 0.5);
            targetPos.add(player.pos);
            Hitbox targetHitbox = new Hitbox(targetPos, 0);
            
            // loop through loaded chunks
            for (Chunk chunk : world.chunks) {
                // if chunk is near target
                if (chunk.outHitbox.overlap(targetHitbox)) {
                    // loop through blocks
                    for (Block block : chunk.blocks) {
                        if (block.getHitbox().overlap(targetHitbox)) {
                            // finish if target hits block
                            finished = true;
                        }
                    }
                    
                    // loop through mobs (copy mobs to avoid ConcurrentModificationException)
                    for (Mob mob : new ArrayList<Mob>(chunk.mobs)) {
                        if (mob.getHitbox().overlap(targetHitbox)) {
                            mob.getHit(player.pos);
                            
                            // set last hit to time
                            lastHit = game.time;
                            
                            // finish loop
                            finished = true;
                        }
                    }
                }
            }
        }
    }
    
    void rightClick() {
        // check if crafting table has been right clicked
        if (target != null) {
            switch (target.name) {
                case "crafting_table":
                    changeState(new Crafting_Menu());
                    break;
                    
                case "chest":
                    changeState(new Chest_Menu((Chest) target));
                    break;
                    
                case "furnace":
                    changeState(new Furnace_Menu((Furnace) target));
                    break;
            }
        }
    }
    
    void eat() {
        if (selectedItem().count > 0 && selectedItem().type.equals("food") && rightMouse && player.getFood() != 20) {
            // start eating if not eating already
            if (eatingStart == -1) {
                eatingStart = game.time; 
            }
        } else {
            // stop eating if no food is being held or mouse isn't pressed
            eatingStart = -1;
        }
        
        // after 1600ms finish eating
        if (game.time - eatingStart > 1600 && eatingStart != -1) {
            eatingStart = -1;
            if (foodPoints.containsKey(selectedItem().name)) {
                // restore player's food points and saturation based on food data
                player.food += foodPoints.get(selectedItem().name);
                player.saturation += foodSaturation.get(selectedItem().name);
                // decrease eaten food count
                selectedItem().count--;
            } else {
                throw new RuntimeException("Food doesn't contain data in data\\food.txt");
            }
        }
    }
        
    void place() {
        // set selected item
        Item item = selectedItem();
        
        // only place block if it can be placed, place cooldown is over and mouse is clicked
        if (rightMouse) {
            if (placeBlock != null && item.count > 0 && item.type.equals("block") && game.time - lastPlace > 250) {
                if (!checkBlocked(new Hitbox(placeBlock, 1))) {
                    // check which chunk it would be in
                    Hitbox center = new Hitbox(placeBlock.x + 0.5, placeBlock.y + 0.5, 0, 0);
                    
                    for (Chunk chunk : world.chunks) {
                        if (center.overlap(chunk.hitbox)) {
                            // place block
                            placeBlock(item.name, placeBlock, chunk);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    // place a block
    void placeBlock(String name, PVector pos, Chunk chunk) {
        Block placedBlock;
        // direction of block placing
        PVector direction = PVector.sub(target.pos, placeBlock);
        
        switch (name) {
            // create special objects in case of special blocks
            case "chest":
                placedBlock = new Chest(pos, 0, chunk);
                break;
                
            case "furnace":
                placedBlock = new Furnace(pos, 0, chunk);
                break;
                
            case "torch":
                placedBlock = new Torch(pos, 0, direction, chunk);
                break;
                
            default:
                placedBlock = new Block(name, pos, 0, chunk);
        }
        
        // if can be placed
        if (placedBlock.canBePlaced(direction)) {
            // add block to chunk
            placedBlock.addToChunk();
            placedBlock.saveChunk();
            
            // decrease item count and save chunk
            selectedItem().count--;
            
            lastPlace = game.time;
        }
    }
    
    // drop item
    void drop(Item item, int count) {
        // make normalized vector from player direction
        PVector dir = PVector.fromAngle(player.direction());
        
        // item pos is around the head
        PVector pos = PVector.add(player.pos, new PVector(player.w/2, player.w/2));
        pos.add(PVector.mult(dir, 0.8));
        pos.sub(0.25, 0.25);
        
        // velocity is player direction with magnitude 0.2
        PVector vel = PVector.mult(dir, 0.2);
        
        // don't drop item if way is blocked by block
        if (! checkBlocked(new Hitbox(pos, 0.5))) {          
            // do count times
            for (int i = 0; i < count && item.count > 0; i++, item.count--) {      
                // create item 
                ItemEntity newItem = new ItemEntity(item.name, pos.copy(), vel.copy(), item.durability);
                
                // add to chunk
                newItem.addToChunk();
                newItem.saveChunk();
            }
            
            lastDrop = game.time;
        }
    }
    
    // change selecting slot
    void changeSlot(int count) {
        select += count;
        select = Math.floorMod(select, 9);
    }
}
