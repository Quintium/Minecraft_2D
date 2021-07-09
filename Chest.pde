// class for chests
class Chest extends Block {
    // initialize chest collection
    Collection col = new Collection(3, 9);
    
    Chest(PVector pos, int layer, Chunk chunk) {
        super("chest", pos, layer, chunk);
    }
    
    @Override
    void finish() {
        // drop all chest items
        for (Item[] row : col.items) {
            for (Item item : row) {
                drop(item);
            }
        }
    }
}

class Chest_Menu extends State {   
    // calculate inventory scale and pos
    int scale = width * 2/5 / 176;
    PVector pos = new PVector((width - scale * 176) / 2, (height - scale * 166) / 2);
    
    // load font for label
    PFont myFont = createFont("Minecraftia.ttf", scale * 7);
    
    // calculate menu hitbox
    Hitbox myHitbox = new Hitbox(pos.x, pos.y, 176 * scale, 166 * scale);
    
    CollectionInteraction interaction;
    
    Chest_Menu(Chest chest) {
        // create collections
        Collection[] collections = {actions.hotbar, actions.inventory, chest.col};
        
        // calculate collection positions based on top left corner of menu
        PVector hotbarPos = new PVector(pos.x + 7 * scale, pos.y + 141 * scale);
        PVector invenPos =  new PVector(pos.x + 7 * scale, pos.y + 83 * scale);
        PVector chestPos =  new PVector(pos.x + 7 * scale, pos.y + 17 * scale);
        PVector[] positions = {hotbarPos, invenPos, chestPos};
        
        // initialize pointers
        Pointer[] pointers = new Pointer[3];
        pointers[0] = new Pointer(chest.col, actions.hotbar, actions.inventory);
        pointers[1] = new Pointer(actions.inventory, chest.col);
        pointers[2] = new Pointer(actions.hotbar, chest.col);
        
        // create collection interaction
        interaction = new CollectionInteraction(collections, positions, pointers, null, 18 * scale, myHitbox);
    }
    
    void drawMenu() {
        // draw inventory image with size scaled up
        image(textures.get("chest_menu"), pos.x, pos.y, 176 * scale, 166 * scale);
        interaction.draw();
        
        // write "Crafting" text
        textFont(myFont);
        textAlign(LEFT, TOP);
        fill(70);
        text("Chest", pos.x + 8 * scale, pos.y + 5 * scale);
        text("Inventory", pos.x + 8 * scale, pos.y + 72 * scale);
    }
    
    void loop() {
        // draw and move world through game, draw inventory
        game.drawWorld();
        drawMenu();
        
        game.moveWorld();
    }
    
    void mousePressed() {
        // pass click to interaction
        if (mouseButton == LEFT) {
            if (! pressedCodes.get(SHIFT)) {
                // pass click to interaction
                interaction.clicked();  
            } else {
                // pass shift click to interaction
                interaction.shiftClicked();
            }   
        } else if (mouseButton == RIGHT) {
            // pass right click to interaction
            interaction.rightClicked();
        }
    }
    
    void mouseReleased() {
        interaction.released(); 
    }
    
    void mouseDragged() {
        interaction.dragged();
    }
    
    void finish() {
        // finish interaction
        interaction.finish();   
    }
    
    void keyPressed() {
        // change state if e was pressed
        if (Character.toLowerCase(key) == 'e') {
            changeState(game);
        }
    }
}
