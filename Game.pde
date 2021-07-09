// abstract class state for managing all the game states (menu, inventory, game...)
abstract class State {
    // main loop
    abstract void loop();
    
    // events
    void start() {}
    void finish() {}
    void mousePressed() {}
    void mouseReleased() {}
    void mouseWheel(int count) {}
    void keyPressed() {}
    void mouseDragged() {}
}

// class for menu button
class Button {
    // button vars
    String text;
    PFont font;
    IntVector pos;
    IntVector size;
    Hitbox hitbox;
    boolean targeted = false;
    
    // constructor with text, center, size
    Button(String text, IntVector center, IntVector size, PFont font) {
        this.text = text;
        this.pos = IntVector.sub(center, IntVector.div(size, 2)); 
        this.size = size;
        this.font = font;
        
        // calculate hitbox of button
        this.hitbox = new Hitbox(pos.x, pos.y, size.x, size.y);
    }
    
    // check for button events
    boolean check() {
        // update targeted var
        if (new Hitbox(mouse, 0).overlap(hitbox)) { 
            targeted = true;
            
            if (leftMouse) {
                // return true if pressed
                return true;
            }
        } else {
            targeted = false;
        }
        
        // return false if not pressed
        return false;
    }
    
    void draw() {
        // draw button at pos with size
        PImage image;
        if (targeted) {
            image = textures.get("targeted_button");
        } else {
            image = textures.get("button");
        }
            
        image(image, pos.x, pos.y, size.x, size.y); 
        
        // draw the text
        textFont(font);
        fill(255);
        textAlign(CENTER, CENTER);
        text(text, pos.x + size.x/2, pos.y + size.y/2);
    }
}

class Game extends State {
    // initialize game time
    long time = 0;
    float dayCycle = 0;
    long lastUpdate;
    
    // initialize heart and food jittering
    long lastHeartUpdate;
    int[] heartsY = new int[10];
    long lastFoodUpdate;
    
    Game() {
        lastUpdate = System.currentTimeMillis(); 
    }
    
    void drawHotbar() {
        // calculate hotbar scale and pos
        int iconScale = (int)(width / 3 / 182);
        IntVector hotbarSize = new IntVector(182*iconScale, 22*iconScale);
        IntVector hotbarPos = new IntVector(width / 3, height - hotbarSize.y);
        
        // calculate icon/heart size and health bar pos
        IntVector iconSize = new IntVector(iconScale * 9, iconScale * 9);
        IntVector healthPos = new IntVector(hotbarPos.x, hotbarPos.y - iconScale * 11);
        
        // draw hotbar image at x=width/3, y=height-22(*scale) with size scaled up
        image(textures.get("hotbar"), hotbarPos.x, hotbarPos.y, hotbarSize.x, hotbarSize.y);
        
        // draw select image, x depends on what slot you selected, same y as hotbar image
        image(textures.get("select"), hotbarPos.x + 20 * iconScale * actions.select, hotbarPos.y, hotbarSize.y, hotbarSize.y); 
        
        // draw hotbar items with scale pixels shifted down and right
        PVector imagePos = new PVector(hotbarPos.x + iconScale, hotbarPos.y + iconScale);
        actions.hotbar.draw(imagePos, iconScale * 20);
        
        // update heart offset if last heart y change was more than 50ms ago and player is low
        if (game.time - lastHeartUpdate > 50 && player.getHearts() <= 4) {
            for (int i = 0; i < 10; i++) {
                // shaking heart effect
                heartsY[i] = (int)random(-1, 2);
            }
            
            lastHeartUpdate = game.time;
        }
        
        // update food offset if player's saturation is used up and last jitter was more than 2s ago
        int[] foodY = new int[10];
        if (game.time - lastFoodUpdate > 2000 && player.saturation == 0) {
            for (int i = 0; i < 10; i++) {
                // shaking heart effect
                foodY[i] = (int)random(-1, 2);
            }
            
            lastFoodUpdate = game.time;
        }
        
        // loop through hearts
        for (int i = 0; i < 10; i++) {
            // shift y by heartsY
            IntVector drawPos = healthPos.copy();
            drawPos.x += i * iconScale * 8;
            if (player.getHearts() <= 4) {
                drawPos.y += heartsY[i] * iconScale;
            }
            
            // draw empty heart in background
            image(textures.get("empty_heart"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
            
            // if damage has been taken and hearts are blinking
            if (game.time - player.damageTime < 600 && (game.time - player.damageTime) % 250 > 100 && player.damageTime != -1) {
                // draw white border
                image(textures.get("empty_heart_bland"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
                
                // draw bland full/half heart
                if (player.healthSave - (i*2) >= 2) {
                    // draw full heart if the heart with index i is full
                    image(textures.get("full_heart_bland"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
                } else if (player.healthSave - (i*2) >= 1) {
                    // draw half heart if the heart with index i is halved
                    image(textures.get("half_heart_bland"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
                }
            }
           
            if (player.health - (i*2) >= 2) {
                // draw full heart if the heart with index i is full
                image(textures.get("full_heart"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
            } else if (player.health - (i*2) >= 1) {
                // draw half heart if the heart with index i is halved
                image(textures.get("half_heart"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
            }
        }
        
        // loop through food bar
        for (int i = 0; i < 10; i++) {
            IntVector drawPos = healthPos.copy();
            drawPos.x += (hotbarSize.x - (i+1)*iconScale*8);
            if (player.saturation == 0 && game.time - lastFoodUpdate < 50) {
                drawPos.y += foodY[i] * iconScale;
            }
            
            // draw empty food in background
            image(textures.get("empty_food"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
           
            if (player.food - (i*2) >= 2) {
                // draw full food if the food with index i is full
                image(textures.get("full_food"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
            } else if (player.food - (i*2) >= 1) {
                // draw half food if the food with index i is halved
                image(textures.get("half_food"), drawPos.x, drawPos.y, iconSize.x, iconSize.y);
            }
        }
    }
    
    void drawWorld() {
        // draw background
        background(200, 210, 255);
        
        // update camera
        camera.update();
        camera.activate();
        
        // draw objects
        world.draw();
        player.render();
        world.drawLight();
        
        // deactivate camera offset for hotbar
        camera.deactivate(); 
        drawHotbar();
    }
    
    void moveWorld() {
        // move the player and world
        player.physics();
        player.updateFood();
        player.getFallDamage();
        player.getCactusDamage();
        player.getItems();
        world.move();
        
        // update world
        world.updateChunks(player.pos.x);
        
        // update in game time and time of day
        time += (System.currentTimeMillis() - lastUpdate) * 1;
        dayCycle = time % 1200000;
        lastUpdate = System.currentTimeMillis();
    }
    
    void doActions() {
        // check actions
        player.motion();
        player.updateAnimation();
        actions.targetBlock();
        actions.breaking();
        actions.place();
        actions.eat();
    }
    
    void loop() {
        // combine subfunctions
        drawWorld();
        moveWorld();
        doActions();
    }
    
    void mouseWheel(int count) {
        // change slot
        actions.changeSlot(count);
    }
    
    void mousePressed() {
        // pass event to actions
        if (mouseButton == LEFT) {
            actions.leftClick();
        } else if (mouseButton == RIGHT) {
            actions.rightClick();
        }
    }
    
    void keyPressed() {
        switch (Character.toLowerCase(key)) {
            // open inventory when e is pressed
            case 'e':
                changeState(new Inventory());
                break;
            
            // drop item if q is pressed
            case 'q':             
                actions.drop(actions.selectedItem(), 1);
                break;
                
            case 'y':
                Mob newMob = new KillerPig(new PVector(player.pos.x, player.pos.y - 0.5));
                newMob.addToChunk();
                break;
        }
    }
}
