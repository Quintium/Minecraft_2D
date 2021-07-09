// class for items in collections

class Item {
    // initialize item properties
    String name;
    PImage im;
    String type;
    String tool;
    String material;
    int count;
    int stack;
    int durability;
    int fullDurability;
    String slotType;
    
    // create item with given slot type
    Item(String name, int count, String slotType) {
        this.name = name;
        this.count = count;
        this.slotType = slotType;
        
        if (name != null) {
            // load data if item isn't empty
            loadData();
        }
    }
    
    // create item without given slot type
    Item(String name, int count) {
        // default slot type
        this(name, count, "all");
    }
    
    void loadData() {
        // default durability
        durability = 1;
        fullDurability = 1;
        
        // load image
        im = textures.get(name);
        
        if (blockNames.contains(name)) {
            // set type to block if name is in blocks
            type = "block";
            stack = 64;
        } else {
            // load item properties from itemData
            Reader reader = new CategoryReader(itemData, name);
            
            while (reader.hasNextLine()) {
                // find keyword and value
                String[] lineSplit = reader.splitLine("=");
                String keyWord = lineSplit[0];
                String value = lineSplit[1];
                
                // change variable based on keyword and value
                switch (keyWord) {
                    case "type":
                        type = value;
                        break;
                    case "tool":
                        tool = value;                            
                        break;
                    case "material":
                        material = value;
                        break;
                    
                    default:
                        throw new RuntimeException("Property " + keyWord + " does not exist.");
                }
            }
        }
        
        // calculate stack size
        stack = type.equals("tool") ? 1 : 64; 
        
        // calculate durability
        if (type.equals("tool")) {
            switch (material) {
                case "gold":
                    durability = 32;
                    break;
                case "wood":
                    durability = 59;
                    break;
                case "stone":
                    durability = 131;
                    break;
                case "iron":
                    durability = 250;
                    break;
                case "diamond":
                    durability = 1561;
                    break;
            }
            
            fullDurability = durability;
        }
    }
    
    // load another item into this item
    void loadItem(Item item) {
        // load all variables
        name = item.name;
        count = item.count;    
        loadData();
        durability = item.durability;
    }
    
    // decrease durability based on item
    void decreaseDurability() {
        if (count > 0) {
            if (type.equals("tool")) {
                durability--;   
            }
            
            // remove itself if durability is gone
            if (durability <= 0) {
                count = 0;   
            }
        }
    }
    
    // add item to item
    void add(Item item, int itemCount) {
        // don't add if item doesn't match slot type
        if (!(slotType.equals("fuel") && !item.isFuel()) && !(slotType.equals("material") && !item.isMaterial())) {
            // if input item isn't empty
            if (item.count != 0) {
                // if this item is empty
                if (count == 0) {
                    name = item.name;
                    
                    // add itemCount items to this item
                    for (int i = 0; i < itemCount && item.count > 0; i++) {
                        item.count--;
                        count++;
                    }
                    
                    loadData();
                    durability = item.durability;
                // if names are the same
                } else if (item.name.equals(name)){
                    // add single item until the item is empty, this item is full or itemCount items have been added
                    for (int i = 0; i < itemCount && item.count > 0 && count < stack; i++) {
                        item.count--;
                        count++;
                    }
                }
            }
        }
    }
    
    // return if item type matches other item type    
    boolean matches(Item item) {
        return count == 0 || item.count == 0 || name.equals(item.name);
    }
    
    // check if item is fuel
    boolean isFuel() {
        // don't check if item is empty
        if (count > 0) {
            // check if item is in group and group is in possible fuels
            for (List<String> group : craftingGroups.keySet()) {
                if (fuels.containsKey(craftingGroups.get(group)) && group.contains(name)) {
                    return true;
                }
            }
            
            // return if fuels contain fuel
            return fuels.containsKey(name);   
        } else {
            return false;
        }   
    }
    
    // check if item is smelting material
    boolean isMaterial() {
        // don't check if item is empty
        if (count > 0) {
            // check if item is in group and group is in possible materials
            for (List<String> group : craftingGroups.keySet()) {
                if (smeltingRecipes.containsKey(craftingGroups.get(group)) && group.contains(name)) {
                    return true;
                }
            }
            
            // return if materials contain fuel
            return smeltingRecipes.containsKey(name);   
        } else {
            return false;
        }   
    }
    
    // copy item
    Item copy() {
        Item newItem = new Item(name, count, slotType);
        newItem.durability = durability;
        return newItem;   
    }
    
    // draw collection item at x, y, with size itemSize
    void draw(PVector pos, int itemSize, boolean center) {
        // only draw if not empty
        if (count > 0) {
            int s;
            // different size depending on type
            if (type == "block") {
                s = (int)(itemSize * 0.6);
            } else {
                s = (int)(itemSize * 0.8);
            }
            
            // different pos based on centering
            PVector drawPos = pos.copy();
            drawPos.sub(s / 2, s / 2);
            if (!center) {
                drawPos.add(itemSize / 2, itemSize / 2);
            }
            
            // draw image with settings
            image(im, drawPos.x, drawPos.y, s, s);
            
            // print count
            if (count > 1) {
                textFont(numFont);
                textAlign(RIGHT, BOTTOM);
                fill(255);
                
                // different textPos based on centering
                PVector textPos = pos.copy();
                textPos.add(itemSize / 2, itemSize / 2);
                textPos.sub(itemSize / 10, itemSize / 20);
                if (!center) {
                    textPos.add(itemSize / 2, itemSize / 2);
                }
                
                text(count, textPos.x, textPos.y);
            }
        }
        
        // draw durability if not full durability
        if (durability < fullDurability && count > 0) {
            // calculate size of durability bar
            int fullSize = (int)(itemSize * 0.65);
            float ratio = (float) durability / fullDurability;
            int size = (int)(ratio * fullSize);

            // calculate color
            int r = (int)((-2 * ratio + 2) * 255);
            int g = (int)((2 * ratio) * 255);
            
            // calculate durability pos
            PVector durPos = pos.copy();
            durPos.add((itemSize - fullSize) / 2, itemSize * 0.75);
            if (center) {
                durPos.sub(itemSize / 2, itemSize / 2);
            }
            
            // draw black background
            noStroke();
            fill(0);
            rect(durPos.x, durPos.y, fullSize, itemSize * 0.1);
            
            // draw colored bar
            fill(r, g, 0);
            rect(durPos.x, durPos.y, size, itemSize * 0.05);  
        }
    }
}

// class for item in the world

class ItemEntity extends Entity {
    String name;
    PImage im;
    int durability;
    
    // create item entity
    ItemEntity(String name, PVector itemPos, PVector itemVel, int durability) {
        // load details
        super(itemPos, 0.5, 0.5);
        vel = itemVel;
        
        this.name = name;
        this.durability = durability;
        
        // random velocity
        vel.add(random(-0.05, 0.05), random(-0.05, 0.05));
        
        // load image and chunk
        im = textures.get(name);
    }
    
    @Override
    void changeChunk(Chunk newChunk) {
        // remove item from old chunk and add to new chunk
        myChunk.items.remove(this);
        newChunk.items.add(this);
        
        saveChunk();
    }
    
    @Override
    void addToChunk() {
        // add item to chunk
        myChunk.items.add(this);
    }
    
    @Override
    void removeFromChunk() {
        // remove item from chunks
        myChunk.items.remove(this);
    }
    
    @Override
    void draw(PVector screenPos) {
        // draw item in world
        image(im, screenPos.x, screenPos.y, 0.5 * blockSize, 0.5 * blockSize);
    }
}
