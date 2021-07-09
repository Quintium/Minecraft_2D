abstract class Entity {
    // create new position, velocity, layer and size
    PVector pos = new PVector(0, 0);
    PVector vel = new PVector(0, 0);
    int layer = 0;
    float w, h;
    Chunk myChunk;
    
    // constructor without given chunk
    Entity(PVector pos, float w, float h) {
        // constructor with no chunk
        this(pos, w, h, null);
        
        // get chunk
        myChunk = getChunk();
        assert myChunk != null;
    }
    
    // constructor with given chunk
    Entity(PVector pos, float w, float h, Chunk chunk) {
        // set width and height, add terminal velocity
        this.pos = pos;
        this.w = w;
        this.h = h;
        
        // set chunk
        myChunk = chunk;
    }
    
    // drop item from entity
    void drop(Item item) {
        // center item pos 
        PVector itemPos = pos.copy();
        itemPos.add(w/2 - 0.25, h/2 - 0.25);
        
        for (; item.count > 0; item.count--) {
            // create item count items
            ItemEntity newItem = new ItemEntity(item.name, itemPos.copy(), new PVector(0, -0.05), item.durability);
            newItem.addToChunk();
            newItem.saveChunk();
        }
    }
    
    // update size after constructor has been called 
    void updateSize(float w, float h) {
        // update size
        this.w = w;
        this.h = h;
       
        // set chunk
        myChunk = getChunk();
    }
    
    void physics() {
        // calculate if entity is within the screen or 13 blocks near it; if yes - do its physics
        PVector screenPos = coordToPos(pos);
        Hitbox cameraHitbox = new Hitbox(camera.x - 13*blockSize, camera.y - 13*blockSize, width + 26*blockSize, height + 26*blockSize);
        
        if (new Hitbox(screenPos.x, screenPos.y, w * blockSize, h * blockSize).overlap(cameraHitbox)) {     
            getReplaced();
            
            // slow movement and fall
            vel.x *= 0.8;
            vel.y += 0.02;
    
            // check if way of x-movement is blocked
            if (checkCollision(vel.x, 0)) {
                // move x a little bit until movement is blocked
                float unit = Math.signum(vel.x) / 1000;
                while (!checkCollision(unit, 0)) {
                    pos.x += unit;
                }
    
                vel.x = 0;
            } else {
                // move x
                pos.x += vel.x;
                
                if (this instanceof Player && player.sprinting) {
                    // increase player exhaustion if entity is player and sprinting
                    player.exhaustion += abs(vel.x) * 0.1;
                }
            }
    
            // do the same for y
            if (checkCollision(0, vel.y)) {
                float unit = Math.signum(vel.y) / 1000;
                while (!checkCollision(0, unit)) {
                    pos.y += unit;
                }
                
                vel.y = 0;
            } else {
                pos.y += vel.y;
            }  
            
            updateChunk();
            
            // round position if position isn't blocked
            PVector roundPos = new PVector(round(pos.x * 100) / 100.0, round(pos.y * 100) / 100.0);
            if (! checkCollision(roundPos.x - pos.x, roundPos.y - pos.y)) {
                pos = roundPos;
            }
        }
    }
    
    void updateChunk() {
        Chunk newChunk = getChunk();
        
        // throw error if entity is not in a chunk
        assert newChunk != null;
        
        // change chunk if it's not current one
        if (newChunk != myChunk) {
            // change chunk
            changeChunk(newChunk);
            myChunk = newChunk;
        }
    }
    
    Chunk getChunk() {
        // check if center of entity is within another chunk; if yes - return it
        for (Chunk chunk : world.chunks) {
            Hitbox center = new Hitbox(pos.x + w / 2, pos.y + h / 2, 0.01, 0.01);
            if (chunk.hitbox.overlap(center)) {
                return chunk;
            }
        }
        
        return null;
    }
    
    boolean checkCollision(float changeX, float changeY) {      
        // check if entity collides with any solid blocks when its position is changed
        Hitbox hitbox = new Hitbox(pos.x + changeX, pos.y + changeY, w, h); 

        for (Chunk chunk : world.chunks) {
            // only check chunks that are close
            if (hitbox.overlap(chunk.outHitbox)) {
                for (Block block : chunk.blocks) {
                    // check if player collides with block
                    if (block.solid && block.layer <= layer && block != this && hitbox.overlap(block.getHitbox())) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
    
    // dodge if block is placed inside of an item
    void getReplaced() {
        // if it's an item and is in block
        if (this instanceof ItemEntity) {
            if (checkCollision(0, 0)) {
                // dirs in which the item can dodge
                PVector[] dirs = {new PVector(1, 0), new PVector(-1, 0), new PVector(0, 1), new PVector(0, -1),
                                  new PVector(1, 1), new PVector(-1, -1), new PVector(-1, 1), new PVector(1, -1)};
                                  
                // while it hasn't finished and max distance isn't reached
                boolean finished = false;
                
                for (float i = 0; !finished && i < 10 ; i+=0.1) {
                    // increment distance by 0.1 and search if one direction is clear
                    for (PVector dir : dirs) {
                        PVector step = PVector.mult(dir, i);
                        
                        if (! checkCollision(step.x, step.y)) {
                            // add that step and finish
                            pos.add(step);
                            finished = true;
                            break;
                        }
                    }
                }
                
                // update and save chunk
                updateChunk();
            }
        }
    }
    
    // returns the top of the entity
    PVector top() {
        PVector topPos = pos.copy();
        topPos.add(w/2, 0);
        return topPos;
    }
    
    // check if entity is on the ground
    boolean onGround() {
        return checkCollision(0, 0.01);
    }
    
    // calculate hitbox
    Hitbox getHitbox() {
        return new Hitbox(pos.x, pos.y, w, h);
    }
    
    // save current chunk
    void saveChunk() {
        world.saveChunk(myChunk);
    }
    
    // methods that are meant to be overridden;
    void changeChunk(Chunk newChunk) {}
    void removeFromChunk() {}
    void addToChunk() {}
    
    abstract void draw(PVector screenPos);
    
    void render() {
        // draw entity if it's within the screen
        PVector screenPos = coordToPos(pos);
        Hitbox drawHitbox = new Hitbox(screenPos.x, screenPos.y, w * blockSize, h * blockSize);
        
        if (camera.inScreen(drawHitbox)) {
            draw(screenPos);
        }
    }
}
