class Inventory extends State {
    // calculate inventory scale and pos
    int scale = width * 2 / 5 / 176;
    PVector pos = new PVector((width - scale * 176) / 2, (height - scale * 166) / 2);
 
    // variable for checking if product has been produced
    boolean produced = false;
    
    // create crafting collections    
    Collection crafting = new Collection(2, 2);
    Collection product = new Collection(1, 1);

    // load font for label
    PFont myFont = createFont("Minecraftia.ttf", scale * 7);
    
    // calculate menu hitbox and create collection interaction
    Hitbox myHitbox = new Hitbox(pos.x, pos.y, 176 * scale, 166 * scale);
    CollectionInteraction interaction;
    
    Inventory() {
        Collection[] collections = {actions.hotbar, actions.inventory, crafting, product};
    
        // calculate collection positions based on top left corner of menu
        PVector hotbarPos = new PVector(pos.x + 7 * scale, pos.y + 141 * scale);
        PVector invenPos =  new PVector(pos.x + 7 * scale, pos.y + 83 * scale);
        PVector craftPos =  new PVector(pos.x + 97 * scale, pos.y + 17 * scale);
        PVector productPos =  new PVector(pos.x + 153 * scale, pos.y + 27 * scale);
        PVector[] positions = {hotbarPos, invenPos, craftPos, productPos};
        
        // initialize pointers
        Pointer[] pointers = new Pointer[4];
        pointers[0] = new Pointer(actions.hotbar, actions.inventory);
        pointers[1] = new Pointer(actions.inventory, actions.hotbar);
        pointers[2] = new Pointer(crafting, actions.inventory, actions.hotbar);
        pointers[3] = new Pointer(product, actions.hotbar, actions.inventory);
        
        interaction = new CollectionInteraction(collections, positions, pointers, product, 18 * scale, myHitbox);
    }
    
    // get product from recipe
    Item getProduct() {
        // loop through recipes
        for (int i = 0; i < products.size(); i++) {
            // return product if there is one
            Recipe recipe = recipes.get(i);
            
            if (recipe.compare(crafting)) {
                return products.get(i).copy();
            }
        }
        
        // return null if no product has been found
        return null;
    }
    
    void addProduct() {
        // get product
        Item newProduct = getProduct();
        
        if (newProduct != null) {
            if (product.item().count == 0) {
                // add new product if there is one and slot is empty
                product.item().add(newProduct, 64);
                produced = true;
            }
        } else {
            // reset product slot if there's no product
            product.item().count = 0;
            produced = false;
        }
    }
    
    // remove crafting items
    void removeRecipe() {
        if (produced && product.item().count == 0) {
            // remove one of every crafting item if product was taken
            for (Item[] row : crafting.items) {
                for (Item item : row) {
                    if (item.count > 0) {
                        item.count--;
                    }
                }
            }
            
            produced = false;
        }
    }
    
    void drawInventory() {
        // draw inventory image with size scaled up
        image(textures.get("inventory"), pos.x, pos.y, 176 * scale, 166 * scale);
        interaction.draw();
        
        // write "Crafting" text
        textFont(myFont);
        textAlign(LEFT, TOP);
        fill(70);
        text("Crafting", pos.x + 97 * scale, pos.y + 5 * scale);
    }
    
    void loop() {
        // draw and move world through game, draw inventory
        game.drawWorld();
        drawInventory();
        
        game.moveWorld();
    }
    
    void mousePressed() {
        if (mouseButton == LEFT) {
            // pass click to interaction if shift isn't pressed
            if (! pressedCodes.get(SHIFT)) {
                interaction.clicked();  
            } else {
                // pass shift click to interaction
                interaction.shiftClicked();
                
                // create new product and pass shiftclick while there's a new product
                while (product.item().count == 0 && getProduct() != null) {
                    // manage crafting
                    removeRecipe();
                    addProduct();
                    
                    interaction.shiftClicked();
                }
            }
        } else if (mouseButton == RIGHT) {
            // pass right click to interaction
            interaction.rightClicked();
        }
        
        // manage crafting
        removeRecipe();
        addProduct();
    }
    
    void mouseReleased() {
        interaction.released(); 
        
        // manage crafting
        removeRecipe();
        addProduct();
    }
    
    void mouseDragged() {
        interaction.dragged();
        
        // manage crafting
        removeRecipe();
        addProduct();
    }
    
    void finish() {
        // finish interaction
        interaction.finish();   
        
        // add to inventory or drop all crafting items
        for (Item[] row : crafting.items) {
            for (Item item : row) {
                actions.addToInventory(item);
                actions.drop(item, 64);
            }
        }
    }
    
    void keyPressed() {
        // change state if e was pressed
        if (Character.toLowerCase(key) == 'e') {
            changeState(game);
        }
    }
}
