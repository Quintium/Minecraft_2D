class Mob extends Entity {
    // time at which mob is hit
    float hitTime = -1;
    
    // health vars
    float health;
    float highest = Float.POSITIVE_INFINITY;
    boolean falling;
    PImage im;
    
    float damage;
    boolean seen;
    
    long damageTime = -1;
    
    int direction = 0;
    
    String[] drops = new String[10];
    float[] chances = new float[10];
    int[][] ranges = new int[10][2];
   
    Mob(String name, PVector pos) {
        // super constructor without size
        super(pos, 0, 0);
        
        // load image
        im = textures.get(name);
        
        // create size vars
        float newWidth = 0;
        float newHeight = 0;
        
        // load mob properties from mob data
        Reader reader = new CategoryReader(mobData, name);
        
        while (reader.hasNextLine()) {
            String[] lineSplit = reader.splitLine("=");
            String keyWord = lineSplit[0];
            String value = lineSplit[1];
            
            // change variable based on keyword and value
            switch (keyWord) {
                case "health":
                    health = Integer.parseInt(value);
                    break;
                case "size":
                    // split size by x and put values as width and height
                    String[] size = value.split("x");
                    newWidth = Float.parseFloat(size[0]);
                    newHeight = Float.parseFloat(size[1]);
                    break;
                case "damage":
                    damage = Float.parseFloat(value);
                    break;
                    
                default:
                    if (keyWord.length() == 5 && keyWord.substring(0, 4).equals("drop")) {
                        // if keyword is drop with a number, set drop with index number to that string
                        int dropNr = Character.getNumericValue(keyWord.charAt(4)) - 1;
                        drops[dropNr] = value;
                    } else if (keyWord.length() == 7 && keyWord.substring(0, 6).equals("chance")) {
                        // if keyword is chance with a number, set chance with index number to that chance
                        int dropNr = Character.getNumericValue(keyWord.charAt(6)) - 1;
                        chances[dropNr] = Float.parseFloat(value);
                    } else if (keyWord.length() == 6 && keyWord.substring(0, 5).equals("range")) {
                        // if keyword is range with a number, set range with index number to that range
                        int dropNr = Character.getNumericValue(keyWord.charAt(5)) - 1;
                        // split string by - to get both ends of range
                        String[] range = value.split("-");
                        ranges[dropNr][0] = Integer.parseInt(range[0]);
                        ranges[dropNr][1] = Integer.parseInt(range[1]);
                    } else {
                        throw new RuntimeException("Mob property " + keyWord + " does not exist.");
                    }
            }
        }
        
        // update width and height
        updateSize(newWidth, newHeight);
        
        falling = false;
    }
   
    // return rounded health
    int getHearts() {
         return (int)health;
    }
    
    // check if mob has fall damage
    void getFallDamage() {
        if (onGround()) {
            if (falling) {
                // take damage based on distance fallen if mob fell
                int distance = (int)(pos.y - highest);
                if (distance > 3) {
                    takeDamage(distance - 3);
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
    void takeDamage(float hearts) {        
        int healthSave = getHearts();
        
        health -= hearts;
        limitHealth();
        
        // die if health is 0
        if (getHearts() == 0) {
            dropAllItems();
            removeFromChunk();
        }
        
        // only do the red animation when the health changes
        if (getHearts() != healthSave) {
            damageTime = game.time;
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
    
    // drop all items
    void dropAllItems() {
        // loop through possible drops
        for (int i = 0; i < drops.length; i++) {
            // if chance
            if (random(1) < chances[i]) {
                // determine random amount between the range
                int amount = (int)random(ranges[i][0], ranges[i][1] + 1);
                // drop that item
                drop(new Item(drops[i], amount));
            }
        }
    }
    
    // get hit
    void getHit(PVector hitPos) {
        // save time of hit and take damage
        hitTime = game.time;
        takeDamage(1);
        
        // make the mob fly in direction
        vel.x = Math.signum(pos.x - hitPos.x) * 0.2;
        vel.y = -0.2;
    }
    
    void actions() {}
    
    @Override
    void changeChunk(Chunk newChunk) {
        // remove mob from old chunk and add to new chunk
        myChunk.mobs.remove(this);
        newChunk.mobs.add(this);
        
        saveChunk();
    }
    
    @Override
    void addToChunk() {
        // add mob to chunk
        myChunk.mobs.add(this);
    }
    
    @Override
    void removeFromChunk() {
        // remove mob from chunks
        myChunk.mobs.remove(this);
    }

    void motion() {}
    
    void jumpIfNeeded() {
        // jump if mob is going into a wall and can jump over it
        if (checkCollision(vel.x * 5, 0) && !checkCollision(vel.x * 5, -1) && onGround()) {
            vel.y = -0.24;
        }   
    }
    
    @Override
    void draw(PVector screenPos) { 
        push();
        if (game.time - damageTime < 500 && damageTime != -1) {
            tint(255, 100, 100);
        }
        image(im, screenPos.x, screenPos.y, w*blockSize, h*blockSize);
        pop();
    }
}

// class for hostile mobs
class HostileMob extends Mob {
    float attackCooldown = -1;
    
    HostileMob(String name, PVector pos) {
        super(name, pos);
    }
    
    // check if mob can see player
    void lookForPlayer() {
        // if player is near mob and is alive
        if (top().dist(player.top()) < 20 && player.alive) {
            // get direction from mob to player
            PVector dir = PVector.sub(player.top(), top());
            
            // loop through possible distances to check if path to player is blocked
            for (float i = 0; i < top().dist(player.top()); i+=0.5) {
                // set distance to i
                PVector change = dir.copy();
                change.setMag(i);
                
                // add change to center of mob to get position of point that is being checked
                PVector checkPos = PVector.add(top(), change);
                Hitbox checkHitbox = new Hitbox(checkPos, 0);
                
                // return if point is in block
                if (world.collidesWith(checkHitbox)) {
                    seen = false;
                    return;
                }
            }
            
            seen = true;
        } else {
            seen = false;
        }
    }
    
    // attack player if possible
    void attack() {
        // if their hitboxes overlap and player is alive
        if (getHitbox().overlap(player.getHitbox()) && player.alive) {
            // if attack cooldown is over
            if (attackCooldown == -1 || game.time - attackCooldown >= 1000) {
                // take damage and update cooldown
                player.takeDamage(damage, true); 
                player.vel.x = Math.signum(player.pos.x - pos.x) * 0.2;
                player.vel.y = -0.2;
                attackCooldown = game.time;
            }
        }
    }
    
    @Override
    void motion() {
        // if mob sees player and is more than 0.5 blocks apart from him
        if (seen) {
            if (abs(top().x - player.top().x) > 0.5) {
                // go towards the player
                vel.x += Math.signum(player.pos.x - pos.x) * 0.006; 
            }
        } else {
            // change direction at a slight chance
            if (random(300) < 1) {
                direction = (int)random(-1, 2);
            }
            
            // go in desired direction
            vel.x += direction * 0.006;
        }
        
        jumpIfNeeded();
    }
    
    void actions() {
        lookForPlayer();
        attack();
    }
}

// class for friendly mobs
class FriendlyMob extends Mob {
    FriendlyMob(String name, PVector pos) {
        super(name, pos);
    }
    
    @Override
    void motion() {
        // if mob got hit less than 15s ago
        if (game.time - hitTime < 15000 && hitTime != -1) {
            // calculate difference of x of mob and x of player
            float difference = top().x - player.top().x;
            
            // if mob is far from player, run away from it
            if (abs(difference) > 3) {
                direction = (int)Math.signum(difference);
            } else {
                // else change direction with a slight chance
                if (random(50) < 1) {
                    direction = -1 + (int)random(2) * 2;
                }
            }
          
            // run in desired direction
            vel.x += direction * 0.012;
        } else {
            // change direction at a slight chance
            if (random(200) < 1) {
                direction = (int)random(-1, 2);
            }
            
            // go in desired direction
            vel.x += direction * 0.006;
        }
        
        jumpIfNeeded();
    }
    
    void actions() {
    }
}
    

class Zombie extends HostileMob {
    float armsAngle;
    float legsAngle;
  
    Zombie(PVector pos) {
        super("zombie", pos);   
    }
    
    void draw() {
        
    }
}

class Pig extends FriendlyMob {
    Pig(PVector pos) {
        super("pig", pos);   
    }
}

class KillerPig extends HostileMob {
    KillerPig(PVector pos) {
        super("killer_pig", pos);   
    }
}
