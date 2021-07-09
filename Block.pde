class Block extends Entity {
    // initialize all block properties
    String name;
    boolean targeted = false;
    PImage im;
    
    float hardness;
    String tool;
    
    // max ten drops
    String[] drops = new String[10];
    float[] chances = new float[10];
    int[][] ranges = new int[10][2];
    String droppable = "true";
    
    int light = 0;
    boolean transparent = false;
    boolean solid = true;
    boolean gravity = false;
    
    // initialize time broken relative to the break time
    float timeBroken = -1;
    
    Block(String name, PVector pos, int layer, Chunk chunk) {
        // initialize entity
        super(pos, 1, 1, chunk);
        
        this.name = name;
        this.layer = layer;
        
        // default drop
        drops[0] = "this";
        chances[0] = 1;
        for (int[] range : ranges) {
            Arrays.fill(range, 1);
        }
        
        // load image
        im = textures.get(name);
        
        // read block properties from blockData
        Reader reader = new CategoryReader(blockData, name);
        
        while (reader.hasNextLine()) {
            String[] lineSplit = reader.splitLine("=");
            String keyWord = lineSplit[0];
            String value = lineSplit[1];
            
            // change variable based on keyword and value
            switch (keyWord) {
                case "hardness":
                    hardness = Float.parseFloat(value);
                    break;
                case "tool":
                    tool = value;
                    break;
                case "droppable":
                    droppable = value;
                    break;
                    
                case "light":
                    light = Integer.parseInt(value);
                    break; 
                case "transparent":
                    transparent = Boolean.parseBoolean(value);
                    break;    
                case "solid":
                    solid = Boolean.parseBoolean(value);
                    break;
                case "gravity":
                    gravity = Boolean.parseBoolean(value);
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
                        throw new RuntimeException("Property " + keyWord + " does not exist.");
                    }
            }
        }
    }
    
    // drop block drops
    void dropItems() {
        if (getDroppable()) {
            // get random number
            float randomNum = random(1);
            
            String newDrop = "none";
            int amount = 1;
            // loop through all possible drops
            for (int i = 0; i < drops.length; i++) {
                randomNum -= chances[i];
                if (randomNum < 0) {
                    // if probability landed on this drop, set newDrop to drop
                    newDrop = drops[i];
                    
                    // get random amount between min and max drop
                    amount = floor(random(ranges[i][0], ranges[i][1] + 1));
            
                    break;
                }
            }
            
            newDrop = newDrop.equals("this") ? name : newDrop;
            
            // don't return anything if drop is nones
            if (! newDrop.equals("none")) {
                // drop new item
                drop(new Item(newDrop, amount));
            }
        }
    }
    
    // finish block after being broken
    void finish() {}
    
    // update block state
    void update() {}
    
    @Override
    void changeChunk(Chunk newChunk) {
        // remove block from old chunk and add to new chunk
        myChunk.blocks.remove(this);
        newChunk.blocks.add(this);
        
        saveChunk();
    }
    
    @Override
    void addToChunk() {
        // add block to chunk
        myChunk.blocks.add(this);
    }
    
    @Override
    void removeFromChunk() {
        // remove block from chunks
        myChunk.blocks.remove(this);
    }
    
    boolean getDroppable() {
        // rank material
        HashMap<String, Integer> ranks = new HashMap<String, Integer>();
        ranks.put("wood", 0);
        ranks.put("gold", 1);
        ranks.put("stone", 2);
        ranks.put("iron", 3);
        ranks.put("diamond", 4);
        
        // return true if block always drops item
        if (droppable.equals("true")) {
            return true;
        // return false if block never drops item
        } else if (droppable.equals("false")) {    
            return false;
        } else {
            // get selected item
            Item item = actions.selectedItem();
            
            // return true if tool is selected and meets the requirements
            if (item.count > 0 && item.type.equals("tool") && tool.equals(item.tool)) {
                if (ranks.get(item.material) >= ranks.get(droppable)) {
                    return true;            
                } else {        
                    return false;
                }    
            } else {    
                return false;    
            }
        }
    }
        
    float getBreakTime() {
        // rank material by speed
        HashMap<String, Integer> ranks = new HashMap<String, Integer>();
        ranks.put("wood", 2);
        ranks.put("stone", 4);
        ranks.put("iron", 6);
        ranks.put("diamond", 8);
        ranks.put("gold", 12);
        
        // calculate time based on block hardness and if block drops item
        float secs = getDroppable() ? hardness * 1.5 : hardness * 5;
        
        // get selected item
        Item item = actions.selectedItem();
        
        // check if the right tool for the block is selected
        if (item.count > 0 && item.type.equals("tool") && tool.equals(item.tool)) {
            // divide by material rank
            secs /= ranks.get(item.material);
        }
        
        // multiply time if player is not on ground
        if (!player.onGround()) {
            secs *= 5;   
        }
        
        // return time in ms
        return secs * 1000; 
        //return 0.001;
    }
    
    // return true if direction isn't diagonal
    boolean canBePlaced(PVector direction) {
        return direction.x == 0 || direction.y == 0;   
    }
    
    @Override
    void draw(PVector screenPos) {
        drawBlock(screenPos);
        
        // if block is being broken draw break textures
        if (timeBroken > -1) {
            image(textures.get("destroy_" + (int)(timeBroken * 10)), screenPos.x, screenPos.y, blockSize, blockSize);   
        }
        
        // draw rectangle around block if it's targeted
        if (actions.target == this) {
            // draw outline
            stroke(0);
            int thickness = blockSize / 50;
            strokeWeight(thickness);
            noFill();
            rect(screenPos.x + thickness / 2, screenPos.y + thickness / 2, blockSize - thickness, blockSize - thickness);
        }
    }
    
    // extracted function for customization in child classes
    void drawBlock(PVector screenPos) {
        // draw image
        image(im, screenPos.x, screenPos.y, blockSize, blockSize);  
    }
}

class Torch extends Block {
    PVector direction;
    
    Torch(PVector pos, int layer, PVector direction, Chunk chunk) {
        // create torch block with direction
        super("torch", pos, layer, chunk);
        this.direction = direction;
    }
    
    @Override
    // can be placed if placed on solid block and direction isn't diagonal
    boolean canBePlaced(PVector direction) {
        return actions.target.solid && (direction.x == 0 || direction.y == 0) && direction.y != -1;   
    }
    
    // overriden drawBlock method to draw wall torches
    @Override
    void drawBlock(PVector screenPos) {
        // rotate by direction x with center of block
        push();
        translate(screenPos.x + blockSize / 2, screenPos.y + blockSize / 2);
        rotate(-direction.x / 2);
        translate(-screenPos.x - blockSize / 2, -screenPos.y - blockSize / 2);
        
        // draw image
        image(im, screenPos.x + direction.x / 3.5 * blockSize, screenPos.y, blockSize, blockSize);
        pop();
    }
}
