// class for furnace
class Furnace extends Block {
    // initialize furnace items
    Collection material = new Collection(1, 1, "material");   
    Collection fuel = new Collection(1, 1, "fuel");   
    Collection product = new Collection(1, 1);  
    
    float smeltingTime = 0.3;
    float remainder = 0;
    float fuelTime;
    
    long lastUpdate;
    PImage imLit;
    
    Furnace(PVector pos, int layer, Chunk chunk) {
        super("furnace", pos, layer, chunk);
        
        // load lit furnace image and save last update
        imLit = textures.get("furnace_lit");
        lastUpdate = game.time;
    }
    
    // overriden drawBlock method to draw lit furnace
    @Override
    void drawBlock(PVector screenPos) {
        // draw lit image when lit, else draw normal image
        if (remainder > 0) {
            image(imLit, screenPos.x, screenPos.y, blockSize, blockSize);  
        } else {
            image(im, screenPos.x, screenPos.y, blockSize, blockSize); 
        }
    }
    
    @Override
    void finish() { 
        // drop all furnace items
        drop(material.item());
        drop(fuel.item());
        drop(product.item());
    }
    
    // check if item in fuel slot is fuel
    boolean containsFuel() {
        return fuel.item().isFuel();
    }
    
    // get lasting time of fuel
    float getFuelTime() {
        // return fuel time of group if fuel is in group
        for (List<String> group : craftingGroups.keySet()) {
            if (fuels.containsKey(craftingGroups.get(group)) && group.contains(fuel.item().name)) {
                return fuels.get(craftingGroups.get(group));
            }
        }  
        
        // return fuel time of fuel
        return fuels.get(fuel.item().name);
    }
    
    // check if item in material slot is material
    boolean containsMaterial() {
        return material.item().isMaterial();
    }
    
    // get product of given material
    Item getProduct() {
        // return product of group if material is in group
        for (List<String> group : craftingGroups.keySet()) {
            if (smeltingRecipes.containsKey(craftingGroups.get(group)) && group.contains(material.item().name)) {
                return smeltingRecipes.get(craftingGroups.get(group)).copy();
            }
        }  
       
        // return product of material
        return smeltingRecipes.get(material.item().name).copy();
    }
    
    @Override
    void update() {
        // caculate time since last update
        float timeDifference = game.time - lastUpdate;
        
        // decrease remainder based on time difference and fuel durability
        if (remainder > 0) {
            // create light source when active
            light = 13;
            remainder -= timeDifference / (fuelTime * 10 * 1000);
        } else {
            light = 0;
        }
        
        // limit remainder to 0
        if (remainder < 0) {
            remainder = 0;
        }
        
        // if fuel is burned and right recipe, set remainder to 1 and decrease fuel 
        if (remainder == 0 && containsFuel() && containsMaterial()) {
            remainder = 1;
            fuelTime = getFuelTime();
            fuel.item().count--;
        }
        
        // check if can produce product and if new product fits to old product
        boolean canProduce;
        if (containsMaterial() && remainder > 0) {
            canProduce = (product.item().count < product.item().stack || product.item().count == 0) && product.item().matches(getProduct());
        } else {
            canProduce = false;
        }
        
        if (canProduce) {
            // increase smelting time if right recipe and right 
            smeltingTime += timeDifference / (10 * 1000);
            
            // add new product and decrease material count if smelting is done
            if (smeltingTime >= 1) {
                smeltingTime = 0;
                product.item().add(getProduct(), 1);
                material.item().count--;
            }
        } else {
            if (containsMaterial()) {
                // decrease smelting time if fuel is gone
                smeltingTime -= timeDifference / (4 * 1000);
                
                // limit smelting time to 0
                if (smeltingTime < 0) {
                    smeltingTime = 0;
                }
            } else {
                // set smelting time to 0 if material is gone
                smeltingTime = 0;
            }
        }

        // update "update time"
        lastUpdate = game.time;
    }
}

class Furnace_Menu extends State {
    Furnace furnace;
    
    // calculate furnace scale and pos
    int scale = width * 2/5 / 176;
    PVector pos = new PVector((width - scale * 176) / 2, (height - scale * 166) / 2);
    
    // load font for label
    PFont myFont = createFont("Minecraftia.ttf", scale * 7);
    
    CollectionInteraction interaction;
    
    Furnace_Menu(Furnace furnace) {
         // create crafting collections    
        Collection[] collections = {actions.hotbar, actions.inventory, furnace.material, furnace.fuel, furnace.product};
        
        // calculate collection positions based on top left corner of menu
        PVector hotbarPos = new PVector(pos.x + 7 * scale, pos.y + 141 * scale);
        PVector invenPos =  new PVector(pos.x + 7 * scale, pos.y + 83 * scale);
        PVector materialPos =  new PVector(pos.x + 55 * scale, pos.y + 16 * scale);
        PVector fuelPos =  new PVector(pos.x + 55 * scale, pos.y + 52 * scale);
        PVector productPos =  new PVector(pos.x + 115 * scale, pos.y + 34 * scale);
        PVector[] positions = {hotbarPos, invenPos, materialPos, fuelPos, productPos};   
        
        // initialize pointers
        Pointer[] pointers = new Pointer[5];
        pointers[0] = new Pointer(actions.hotbar, furnace.material, furnace.fuel, actions.inventory);
        pointers[1] = new Pointer(actions.inventory, furnace.material, furnace.fuel, actions.hotbar);
        pointers[2] = new Pointer(furnace.material, actions.inventory, actions.hotbar);
        pointers[3] = new Pointer(furnace.fuel, actions.inventory, actions.hotbar);
        pointers[4] = new Pointer(furnace.product, actions.hotbar, actions.inventory);
        
        // calculate menu hitbox and create collection interaction
        Hitbox myHitbox = new Hitbox(pos.x, pos.y, 176 * scale, 166 * scale);
        interaction = new CollectionInteraction(collections, positions, pointers, furnace.product, 18 * scale, myHitbox);
        
        // save furnace
        this.furnace = furnace;
    }
    
    void drawFurnace() {
        // draw furnace image with size scaled up
        image(textures.get("furnace_menu"), pos.x, pos.y, 176 * scale, 166 * scale);
        interaction.draw();
       
        // calculate arrow length
        int arrowLength = (int)(24 * furnace.smeltingTime);
        float scaledArrowLength = (float) arrowLength * scale;
        
        // draw arrow
        PImage arrow = textures.get("arrow").get(0, 0, arrowLength, 17);
        image(arrow, pos.x + 80 * scale, pos.y + 34 * scale, scaledArrowLength, 17 * scale);
        
        // calculate burn height
        int burnHeight = ceil(14 * furnace.remainder);
        float scaledBurnHeight = (float) burnHeight * scale;

        // draw burning
        PImage burning = textures.get("burning").get(0, 14 - burnHeight, 14, burnHeight);
        image(burning, pos.x + 56 * scale, pos.y + 50 * scale - scaledBurnHeight, 14 * scale, scaledBurnHeight);
        
        // write "Furnace" and "Inventory" text
        textFont(myFont);
        textAlign(LEFT, TOP);
        fill(70);
        text("Furnace", pos.x + 64 * scale, pos.y + 5 * scale);
        text("Inventory", pos.x + 8 * scale, pos.y + 71 * scale);
    }
    
    void loop() {
        // draw and move world through game, draw inventory
        game.drawWorld();
        drawFurnace();
        
        game.moveWorld();
    }
    
    void mousePressed() {
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
