class Player extends Entity {
    // initialize variables
    boolean sprinting = false;
    
    float imWidth;
    float imHeight;
    
    PVector topLeft;
    
    // walking animation vars
    float arm1Angle = 0;
    float arm2Angle = 0;
    float leg1Angle = 0;
    float leg2Angle = 0;
    
    long jumpStart = -1;
    long runStart = -1;
    long walkStart = -1;
    long actionStart = -1;
    
    // health vars
    float health;
    float highest = Float.POSITIVE_INFINITY;
    boolean falling;
    long damageTime = -1;
    int healthSave;
    
    float food;
    float saturation;
    float exhaustion;
    long foodTimer = -1;
    
    long cactusCooldown = -1;
    
    float spawnPoint = 0;
    boolean alive;
   
    Player() {
        // entity with width 0.45, height 1.8
        super(world.getSpawn(), 0.45, 1.8);
        
        // calculate image size
        imWidth = w * blockSize;
        imHeight = h * blockSize;
        
        // calculate top left corner of image
        topLeft = new PVector(width / 2 - imWidth / 2, height / 2 - imHeight / 2);
    }
    
    void spawn() {
        // set spawn point right over the world height
        pos = world.getSpawn();
        health = 20;
        food = 20;
        saturation = 0;
        exhaustion = 0;
        alive = true;
        falling = false;
    }
    
    // return rounded health
    int getHearts() {
         return (int)health;
    }
    
    // return rounded food
    int getFood() {
         return (int)food;
    }
    
    // update food points
    void updateFood() {   
        if (food >= 17 || food == 0) {
            // if food is high or low start regeneration/staving
            if (foodTimer == -1) {
                foodTimer = game.time;
            }
        } else {
            // reset regeneration
            foodTimer = -1;
        }
        
        // if you are regenerating
        if (foodTimer != -1) {
            if (food == 20 && game.time - foodTimer > 500) {
                // if health bar is full gain health based on saturation up to 1 every 500ms
                float gain = saturation / 6;
                gain = gain < 1 ? gain : 1;
                takeDamage(-gain, false);
                
                foodTimer = game.time;
            }
            
            // every 4000ms
            if (game.time - foodTimer > 4000) {
                if (food >= 17) {
                    // if food is high, regenerate
                    takeDamage(-1, false);
                } else if (getHearts() >= 2) {
                    // if food is low, starve
                    takeDamage(1, false);
                }
                
                foodTimer = game.time;
            }
            
            limitFood();
        }
        
        if (exhaustion >= 4) {
            // lower saturation if exhausted
            exhaustion = 0;
            saturation -= 1;
            limitFood();
            
            // if saturation is gone, lower food
            if (saturation == 0) {
                food -= 1;
                limitFood();
            }
        }
    }
    
    // get damage from cacti
    void getCactusDamage() {
        // loop through chunks
        for (Chunk chunk : world.chunks) {
            // only if chunks is near player
            if (getHitbox().overlap(chunk.outHitbox)) {
                // find cactus blocks that are overlapping with player
                for (Block block : chunk.blocks) {
                    if (block.name.equals("cactus") && getHitbox().overlap(block.getHitbox())) {
                        // if more than 500ms have passed since last damage from cactus
                        if (cactusCooldown == -1 || game.time - cactusCooldown > 500) {
                            // take damage and update cooldown
                            takeDamage(1, true);
                            cactusCooldown = game.time;
                        }
                    }
                }
            }   
        }
    }
    
    // check if player has fall damage
    void getFallDamage() {
        if (onGround()) {
            if (falling) {
                // take damage based on distance fallen if player fell
                int distance = (int)(pos.y - highest);
                if (distance > 3) {
                    takeDamage(distance - 3, true);
                }
                
                // reset falling
                falling = false;
                highest = Float.POSITIVE_INFINITY;
            }
        } else {
            // set falling var
            if (!falling) {
                falling = true;
            }
            
            // set highest altitude
            if (pos.y < highest) {
                highest = pos.y;
            }
        }
    }
    
    // take damage and save time and severity of damage
    void takeDamage(float hearts, boolean exhausting) {
        // only do the effect when the health has changed
        healthSave = getHearts();
        
        health -= hearts;
        limitHealth();
        
        // die if health is 0
        if (getHearts() == 0) {
            changeState(new Death());
            alive = false;
            dropAllItems();
        }
        
        // only do the animation when the health changes
        if (getHearts() != healthSave) {
            damageTime = game.time;
        }
        
        // increase player exhaustion if damage taken
        if (getHearts() < healthSave && exhausting) {
            player.exhaustion += (healthSave - getHearts()) * 0.1;
        }
    }
    
    // limit health
    void limitHealth() {
        if (health < 0) {
            health = 0;
        }
        if (health > 20) {
            health = 20;
        }
    }
    
    // limit food
    void limitFood() {
        if (food < 0) {
            food = 0;
        }
        if (food > 20) {
            food = 20;
        }
        if (saturation < 0) {
            saturation = 0;
        }
        if (saturation > food) {
            saturation = food;
        }
    }
    
    // drop all items
    void dropAllItems() {
        // drop all hotbar items
        for (Item[] row : actions.hotbar.items) {
            for (Item item : row) {
                drop(item);
            }
        }
        
        // drop all inventory items
        for (Item[] row : actions.inventory.items) {
            for (Item item : row) {
                drop(item);
            }
        }
    }
    
    // drop item when dead
    void drop(Item item) {
        for (; item.count > 0; item.count--) {
            ItemEntity newItem = new ItemEntity(item.name, pos.copy(), new PVector(0, 0), item.durability);
            newItem.addToChunk();
            newItem.saveChunk();
        }
    }

    void motion() {
        // move based on pressed keys
        if (pressedKeys.get('w')) {
            // jump if ground is under player and hasn't jumped since 300ms
            if (onGround() && game.time - jumpStart > 300) {
                vel.y = -0.25;
                jumpStart = game.time;
                
                // increase exhaustion when sprint/normal jumping
                if (sprinting) {
                    exhaustion += 0.1;
                } else {
                    exhaustion += 0.05;
                }
            }
        }
        
        // change sprinting based on player food and shift key
        sprinting = pressedCodes.get(SHIFT) && food > 6;

        float xChange = 0;
        
        // change velocity and direction when a or d are pressed
        if (pressedKeys.get('a')) {
            xChange = -0.02;
        }

        if (pressedKeys.get('d')) {
            xChange = 0.02;
        }
        
        // change x change based on sprinting and eating
        if (sprinting) xChange *= 2;
        if (actions.getEating()) xChange /= 2;
        vel.x += xChange;
        
        // if animation is over
        if (arm1Angle > -0.1 && arm1Angle < 0.1) {
            if (pressedKeys.get('a') || pressedKeys.get('d')) {
                if (pressedCodes.get(SHIFT)) {
                    if (runStart == -1) {
                        // start running if shift is pressed
                        runStart = game.time;
                        walkStart = -1;
                    }
                } else {
                    if (walkStart == -1) {
                        // start walking if shift is not pressed
                        runStart = -1;
                        walkStart = game.time;
                    }
                }
            } else {
                // stop walking/running
                runStart = -1;
                walkStart = -1;
            }
        }
        
        // if any 
        if (actions.getBreaking() || actions.getPlacing() || actions.getEating() || actions.getHitting() || actions.getDropping()) {
            if (actionStart == -1) {
                actionStart = game.time;
            }
        } else {
            actionStart = -1;   
        }
    }
    
    void updateAnimation() {  
        // update running animation
        if (runStart != -1) {
            // set angles to sine of time passed when running
            float sine = sin((game.time - runStart) / 80f);
            
            arm1Angle = sine / 1.7;   
            arm2Angle = -sine / 1.7; 
            leg1Angle = sine / 1.5;   
            leg2Angle = -sine / 1.5; 
        } else if (walkStart != -1) {
            // set angles to sine of time passed when walking
            float sine = sin((game.time - walkStart) / 100f);
            
            arm1Angle = sine / 1.7;   
            arm2Angle = -sine / 1.7; 
            leg1Angle = sine / 1.5;   
            leg2Angle = -sine / 1.5;
        } else {
            // reset animation if not running
            arm1Angle = 0;
            arm2Angle = actions.selectedItem().count > 0 ? 0.6 * getMirrored() : 0;
            leg1Angle = 0;
            leg2Angle = 0;
        }
        
        // set arm angle to sine of time passed plus player direction when breaking
        if (actionStart != -1) {
            arm2Angle = -cos((game.time - actionStart) / 30f) * getMirrored() / 2 + direction() - PI/2;
        }
    }
    
    void getItems() {
        // only if alive
        if (alive) {
            // check if player collides with any items
            Hitbox hitbox = new Hitbox(pos.x, pos.y, 0.45, 1.8); 
    
            for (Chunk chunk : world.chunks) {
                // only check chunks near the player
                if (getHitbox().overlap(chunk.outHitbox)) {
                    for (ItemEntity item : new ArrayList<ItemEntity>(chunk.items)) {
                        if (hitbox.overlap(item.getHitbox())) {
                            // convert item entity into item
                            Item newItem = new Item(item.name, 1);
                            newItem.durability = item.durability;
                            
                            // add to inventory
                            actions.addToInventory(newItem);
                            
                            // remove item entity if it's empty
                            if (newItem.count == 0) {
                                chunk.items.remove(item);
                            }
                        }
                    }
                }
            }
        }
    }
    
    // calculate angle to mouse from head of player
    float direction() {
        return adjusted().heading();
    }
    
    // calculate block distance to mouse from head of player
    float distance() {
        return PVector.div(adjusted(), blockSize).mag();
    }
    
    // return adjusted mouse vector with (0, 0) in players head
    PVector adjusted() {
        return PVector.sub(mouse, getHead());
    }
    
    // return center of head
    PVector getHead() {
        return PVector.add(topLeft, toScreen(4, 4));
    }
    
    // return if player points to right
    int getMirrored() {
        return direction() > -PI/2 && direction() < PI/2 ? -1 : 1;
    }

    @Override
    void draw(PVector screenPos) { 
        // draw only if alive
        if (alive) {
            push();
            
            // if player takes damage, tint player red
            if (game.time - damageTime < 500 && damageTime != -1 && healthSave - getHearts() > 0) {
                tint(255, 100, 100);
            }
            
            // calculate body part sizes, positions and centers of rotation
            PVector bodySize = toScreen(4, 12); 
            PVector bodyPos = imagePos(2, 8);
            PVector armCenter = imagePos(4, 8);
            PVector legPos = imagePos(2, 20);
            PVector legCenter = imagePos(4, 20);
            
            // calculate head center and size
            PVector headCenter = imagePos(4, 8);
            PVector headSize = toScreen(8, 8);
            
            // calculate angle of the head by mirroring the angle to the mouse (because head is flipped)
            float headAngle = floatMod(PI + direction(), 2*PI);
            
            // mirror if head is pointing backwards
            int mirror = getMirrored();
            if (mirror == -1) {
                // change head angle by 180° and inverse it to counter mirroring
                headAngle += PI;
            }
            
            // draw both legs
            rotateImage(textures.get("leg1"), legPos, legCenter, bodySize, leg1Angle, 0, mirror);
            rotateImage(textures.get("leg2"), legPos, legCenter, bodySize, leg2Angle, 0, mirror);
            
            // draw one arm in front of the body and one behind
            rotateImage(textures.get("arm1"), bodyPos, armCenter, bodySize, arm1Angle, 0, mirror);
            rotateImage(textures.get("body"), bodyPos, armCenter, bodySize, 0, 0, mirror);
            rotateImage(textures.get("arm2"), bodyPos, armCenter, bodySize, arm2Angle, 0, mirror);
            
            // draw head with mirrored angle to save the angle
            rotateImage(textures.get("head"), topLeft, headCenter, headSize, headAngle, 0, mirror);
            
            // draw the held block
            if (actions.selectedItem().count > 0) {
                PImage heldBlock = textures.get(actions.selectedItem().name);
                PVector blockPos = imagePos(-3, 16);
                PVector blockSize = toScreen(8, 8);
                rotateImage(heldBlock, blockPos, armCenter, blockSize, arm2Angle, PI*5/4, mirror);
            }
            
            pop();
        }
    }
    
    float floatMod(float a, float b) {
        return a - floor(a / b) * b;
    }
    
    // return a vector with n skin pixels from top left corner of skin
    PVector imagePos(int xPixels, int yPixels) {
        return PVector.add(topLeft, toScreen(xPixels, yPixels));
    }
    
    // turn skin pixels into vector
    PVector toScreen(int xPixels, int yPixels) {
        return new PVector(xPixels * (imWidth / 8), yPixels * (imWidth / 8));
    }
    
    // rotate and mirror image
    void rotateImage(PImage image, PVector imPos, PVector center, PVector size, float angle, float angle2, int mirror) {
        push();
        
        // rotate and scale image around input center
        translate(center.x, center.y);
        rotate(angle);
        scale(mirror, 1);
        translate(-center.x, -center.y);
        
        // rotate and scale image around image center
        translate(imPos.x + size.x / 2, imPos.y + size.y / 2);
        rotate(angle2);
        translate(-imPos.x - size.x / 2, -imPos.y - size.y / 2);
        
        image(image, imPos.x, imPos.y, size.x, size.y);
        
        pop();
    }
}
