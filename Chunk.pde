float seedRandom(float x, float start, float limit, int layer) {
    // return random value based on x, layer and seed
    randomSeed((long) x * seed + 100000 * layer + seed);
    float result = random(start, limit);
    
    // set randomSeed to random number for item and mob drops
    randomSeed(new Random().nextInt(1000000));
    
    return result;
}

float layerNoise(float x, float smoothness, int layer) {
    // return 1D noise based on x, smoothness and layer
    return noise(x / smoothness + 100000 * layer);
}

float layerNoise(float x, float y, float smoothness, int layer) {
    // return 2D noise based on x, smoothness and layer#
    float noiseValue = (float) noise.eval(x / smoothness + 100000 * layer, y / smoothness + 100000 * layer);
    
    // normalize values
    return (noiseValue + 1) / 2;
}

class Chunk {
    // initialize variables
    int x;
    float lowest, highest;
    List<Block> blocks = new ArrayList<Block>();
    List<ItemEntity> items = new ArrayList<ItemEntity>();
    List<Mob> mobs = new ArrayList<Mob>();
    Hitbox hitbox, outHitbox;
    
    Chunk(int x) {
        this.x = x;
        
        // generate hitbox of the chunk and hitbox of possible blocks stored in chunk
        hitbox = new Hitbox(x, -10000, chunkX, 20000);
        outHitbox = new Hitbox(x - 0.6, -10000, chunkX + 0.6, 20000);
        
        updateBounds();
    }
    
    void generate() {
        // check if chunk has been saved
        boolean chunkSaved = false;
        
        for (Chunk chunk : world.savedChunks) {
            if (x == chunk.x) {
                // load chunk
                blocks = chunk.blocks;
                items = chunk.items;
                mobs = chunk.mobs;
                chunkSaved = true;
                break;
            }
        }
        
        // generate chunk if existing chunk has not been found
        if (!chunkSaved) {
            // initialize wood and leaves ArrayLists
            HashMap<String, List<PVector>> specialBlocks = new HashMap<String, List<PVector>>();
            
            specialBlocks.put("oak_leaves", new ArrayList<PVector>());
            specialBlocks.put("birch_leaves", new ArrayList<PVector>());
            specialBlocks.put("oak_log", new ArrayList<PVector>());
            specialBlocks.put("birch_log", new ArrayList<PVector>());
            
            // loop through all relevant possible tree positions
            for (float i = x - 2; i < x + chunkX + 2; i++) {
                // if a tree has been generated there
                if (seedRandom(i, 0, 1, 1) > 0.9 && world.biomes.get(i).equals("forest")) {
                    // get terrain height and treeHeight
                    float h = world.heights.get(i);
                    float treeHeight = floor(seedRandom(i, 2, 6, 2));
                    String wood = seedRandom(i, 0, 1, 3) > 0.5 ? "oak_log" : "birch_log";
                    String leaves = seedRandom(i, 0, 1, 3) > 0.5 ? "oak_leaves" : "birch_leaves";
                    
                    // add wood column with height treeHeight
                    for (float j = h - 1; j > h - 1 - treeHeight; j--) {
                        PVector blockPos = new PVector(i, j);
                        specialBlocks.get(wood).add(blockPos);
                    }
                    
                    // add 5 blocks wide and 2 blocks tall leaves rectangle 
                    for (float j = h - 1 - treeHeight; j > h - 3 - treeHeight; j--) {
                        for (int k = -2; k < 3; k++) {
                            PVector blockPos = new PVector(i + k, j);
                            specialBlocks.get(leaves).add(blockPos);
                        }
                    }
                    
                    // add 3 blocks wide and 2 blocks tall leaves rectangle on the top
                    for (float j = h - 3 - treeHeight; j > h - 5 - treeHeight; j--) {
                        for (int k = -1; k < 2; k++) {
                            PVector blockPos = new PVector(i + k, j);
                            specialBlocks.get(leaves).add(blockPos);
                        }
                    }
                }
            }
                                                         
            // loop through every possible block
            for (float i = x; i < x + chunkX; i++) {
                for (float j = 0; j < 100; j++) {
                    Block block = generateBlock(i, j, specialBlocks);
                    
                    if (block != null) {
                        block.addToChunk();
                    }
                }
            }   
        } 
    }
    
    // update highest and lowest level
    void updateBounds() {
        highest = Float.NEGATIVE_INFINITY;
        lowest = Float.POSITIVE_INFINITY;
        
        for (Block block : blocks) {
            if (block.pos.y > highest) {
                highest = block.pos.y;
            } 
            if (block.pos.y < lowest) {
                lowest = block.pos.y;
            }   
        }
    }
    
    Block generateBlock(float i, float j, HashMap<String, List<PVector>> specialBlocks) {
        // get noise based on position of column
        float h = world.heights.get(i);
        
        // convert position into vector, initialize block type
        PVector blockPos = new PVector(i, j);
        String block = null;
        int layer = 0;
        
        // calculate if block is in a diagonal cave
        boolean cave = layerNoise(i/3.5, j + i/2.5, 10, 3) < 0.2 || layerNoise(i/3.5, j - i/2.5, 10, 4) < 0.2;
        
        // add grass/sand block on the top
        if (j == h) {
            if (!cave) {
                if (world.biomes.get(i) == "forest") {
                    block = "grass_block";
                } else {
                    block = "sand";
                }
            }
        } else if (j > h && j < h + 6) {
            // add dirt below grass
            if (!cave) {
                if (world.biomes.get(i) == "forest") {
                    block = "dirt";
                } else {
                    // add sand and deep sandstone
                    if (j < h + 4) {
                        block = "sand";
                    } else {
                        block = "sandstone";   
                    }
                }
            }
        } else if (j == 99) {
            // add bedrock at the bottom
            block = "bedrock";   
        } else if (j >= h + 5 && j < 100) {
            // generate ore based on 2d noise and height
            if (!cave) {
                if        (layerNoise(i, j, 5, 5) < 0.18 && j > 50 && j < 95) {
                    block = "coal_ore";
                } else if (layerNoise(i, j, 4.5, 6) < 0.13 && j > 50 && j < 95) {
                    block = "iron_ore";
                } else if (layerNoise(i, j, 5.5, 7) < 0.1 && j > 70 && j < 95) {
                    block = "gold_ore";
                } else if (layerNoise(i, j, 5.5, 8) < 0.08 && j > 85 && j < 95) {
                    block = "diamond_ore";
                } else if (layerNoise(i, j, 10, 9) < 0.18) {
                    block = "granite";
                } else if (layerNoise(i, j, 10, 10) < 0.18) {
                    block = "diorite";
                } else if (layerNoise(i, j, 10, 11) < 0.18) {
                    block = "gravel";
                } else {
                    block = "stone";
                }   
            }
        } else if (j < h) {
            // if biome is desert
            if (world.biomes.get(i).equals("desert")) {
                // if random is less than 8% and block is on floor, dead bush
                if (seedRandom(i, 0, 1, 3) < 0.08 && j == h - 1) {
                    block = "dead_bush";
                }  
                
                // if random is less then 10% and block is less than height blocks from floor, cactus
                if (seedRandom(i, 0, 1, 4) < 0.1 && j > h - floor(seedRandom(i, 1, 4, 5))) {
                    block = "cactus";
                    layer = 1;
                }
            }
            
            for (String name : specialBlocks.keySet()) {
                for (PVector pv : specialBlocks.get(name)) {
                    if (pv.x == i && pv.y == j) {
                        block = name;   
                        layer = 1;
                    }
                }
            }
        }
        
        // add block
        if (block != null) {
            return new Block(block, blockPos, layer, this);  
        } else {
            return null;
        }
    }
    
    void move() {
        // loop through copy of items and blocks to avoid a ConcurrentModificationException
        for (ItemEntity item : new ArrayList<ItemEntity>(items)) {
            // do the item physics
            item.physics();
        }
        
        for (Block block : new ArrayList<Block>(blocks)) {
            // if block has gravity do its physics
            if (block.gravity) {
                block.physics();
            }
            
            // update block
            block.update();
        }
        
        for (Mob mob : new ArrayList<Mob>(mobs)) {
            // do the mob physics and actions
            mob.motion();
            mob.getFallDamage();
            mob.physics();
            mob.actions();
        }
    }
    
    void drawWorld() {
        // draw every block, item
        for (Block block : blocks) {
            block.render();   
        }
        
        for (ItemEntity item : items) {
            item.render();  
        }
    }
    
    void drawMobs() {
        // draw every mob
        for (Mob mob : mobs) {
            mob.render();   
        }
    }
}
