class World {
    // initialize heights and chunks
    ArrayList<Chunk> chunks = new ArrayList<Chunk>();
    ArrayList<Chunk> savedChunks = new ArrayList<Chunk>();
    HashMap<Float, Float> heights = new HashMap<Float, Float>();
    HashMap<Float, Float> trees = new HashMap<Float, Float>();
    HashMap<Float, String> biomes = new HashMap<Float, String>();
    
    // vectors for start and end of chunks
    int start, end;
    
    // 4 directions
    IntVector[] dirs = {new IntVector(0, 1), new IntVector(0, -1), new IntVector(1, 0), new IntVector(-1, 0)};
    
    void updateChunks(float x) {  
        // calculate the range of the screen
        float blockStart = 0;
        float blockEnd = 0;
        blockStart = x - (width / 2 / blockSize) - 15;
        blockEnd = x + (width / 2 / blockSize) + 15;
        
        // calculate range of screen based on chunks
        start = floor(blockStart / chunkX) * chunkX;
        end = ceil(blockEnd / chunkX) * chunkX;
        
        calculateData();
        
        // make new chunks arraylist
        ArrayList<Chunk> newChunks = new ArrayList<Chunk>();
        
        // loop through all new positions of chunks
        for (int i = start; i < end; i+=chunkX) {
            // check if chunk has been created
            boolean chunkFound = false;
            for (Chunk chunk : chunks) {
                if (chunk.x == i) {
                    // add existing chunk
                    newChunks.add(chunk);
                    chunkFound = true;
                }
            }
            
            if (!chunkFound) {
                // create new chunk
                Chunk newChunk = new Chunk(i);
                newChunks.add(newChunk);
                newChunk.generate();
            }
        }
        
        chunks = newChunks;
    }
    
    void calculateData() {
        // make new arraylists
        HashMap<Float, Float> newHeights = new HashMap<Float, Float>();
        HashMap<Float, String> newBiomes = new HashMap<Float, String>();
        
        // calculate values for chunks
        for (float i = start - 2; i < end + 2; i++) {
            // if data already has been calculated, put the previous value
            if (heights.containsKey(i)) {
                newHeights.put(i, heights.get(i));
                newBiomes.put(i, biomes.get(i));
            } else {
                // calculate height
                float noiseValue = (float)Math.floor(50 - (layerNoise(i, 30, 1) + layerNoise(i, 20, 2)) * 20);
                newHeights.put(i, noiseValue);
                
                // calculate biome
                float biome = layerNoise(i, 0, 100, 3);
                
                if (biome < 0.7) {
                    newBiomes.put(i, "forest");
                } else {
                    newBiomes.put(i, "desert");
                }        
            }
        } 
        
        // change data
        heights = newHeights;
        biomes = newBiomes;
    }
    
    boolean collidesWith(Hitbox h) { 
        // check if hitbox collides with any solid blocks
        for (Chunk chunk : world.chunks) {
            // only check chunks that are close
            if (h.overlap(chunk.outHitbox)) {
                for (Block block : chunk.blocks) {
                    // check if hitbox collides with block
                    if (block.solid && block.layer == 0 && h.overlap(block.getHitbox())) {
                        return true;
                    }
                }
            }
        }

        return false;
    }
    
    PVector getSpawn() {
        float playerSpawn;
        if (player != null) {
            // set spawn to player's current spawn
            playerSpawn = player.spawnPoint;
        } else {
            // set default spawn if no player
            playerSpawn = 0;
        }
        
        // load chunks near spawn point
        updateChunks(playerSpawn);
        
        // loop through 21 blocks around the spawnpoint (to find a good spawn)
        for (float i = -10; i < 11; i++) {
            float currentX = playerSpawn + i;
            
            // make a vertical player hitbox
            Hitbox playerWidth = new Hitbox(currentX, -10000, 0.45, 20000);
            
            // loop through chunks near the hitbox
            for (Chunk chunk : chunks) {
                if (playerWidth.overlap(chunk.outHitbox)) {
                    // find grass block in blocks which is at the x of player
                    for (Block block : chunk.blocks) {
                        if (playerWidth.overlap(block.getHitbox()) && block.name.equals("grass_block")) {
                            // check if pos above grass block is obstructed
                            PVector playerPos = new PVector(currentX, block.pos.y - 1.8);
                            Hitbox playerHitbox = new Hitbox(playerPos.x, playerPos.y, 0.45, 1.8);

                            if (!collidesWith(playerHitbox)) {
                                // if not, return pos above the grass block
                                return playerPos;
                            }
                        }
                    }
                }
            }
        }
        
        // if no free grass block has been found, find the highest solid block at spawn point
        Hitbox playerWidth = new Hitbox(playerSpawn, -10000, 0.45, 20000);
        float highest = Float.POSITIVE_INFINITY;
        for (Chunk chunk : chunks) {
            // only check chunks that overlap with player
            if (playerWidth.overlap(chunk.outHitbox)) {
                for (Block block : chunk.blocks) {
                    if (playerWidth.overlap(block.getHitbox()) && block.solid && block.layer == 0 && block.pos.y < highest) {
                        // replace highest
                        highest = block.pos.y;
                    }
                }
            }
        }
        
        // return the pos above highest block
        return new PVector(playerSpawn, highest - 1.8);
    }
    
    // flood fill algorithm
    void fillSpace(IntVector pos, int light, boolean[][] tiles, int[][] lighted, boolean original, boolean sky) {
        // calculate internal light
        int internal = light;
        if (sky) {
            // change sky light based on day cycle
            internal += lightLoss();
        }
        
        // return if index is out of boundaries
        if (pos.x < 0 || pos.x >= tiles.length || pos.y < 0 || pos.y >= tiles[0].length) {
            return;
        // return if internal light is 0
        } else if (internal == 0) {
            return;
        } else {
            // change light level if it's less than new one
            if (internal > lighted[pos.x][pos.y]) {
                lighted[pos.x][pos.y] = internal;
                
                // spread if it's not in a block or if it's the light source
                if (!tiles[pos.x][pos.y] || original) {
                    // redo algorithm in four different directions with lower light level
                    for (IntVector dir : dirs) {
                        // don't change if light is spreading down and it's full sky light
                        int newLight = light;
                        if (!(dir.y == 1 && sky && light == 15)) {
                            newLight--;
                        }
                        
                        fillSpace(IntVector.add(pos, dir), newLight, tiles, lighted, false, sky);
                    }
                }
            }
        }
    }
    
    void drawLight() {
        // calculate y chunk boundaries
        int startY = Integer.MAX_VALUE;
        int endY = Integer.MIN_VALUE;
        for (Chunk chunk : chunks) {
            chunk.updateBounds();
            if (floor(chunk.lowest) < startY) {
                startY = floor(chunk.lowest);
            }
            if (ceil(chunk.highest + 1) > endY) {
                endY = ceil(chunk.highest + 1);
            }
        }
        
        // calculate screen boundaries
        int lowerBorder = floor(posToCoord(new PVector(0, 0)).y);
        int upperBorder = ceil(posToCoord(new PVector(0, height)).y) + 1;
        if (lowerBorder < startY) {
            startY = lowerBorder;
        }
        if (upperBorder > endY) {
            endY = upperBorder;
        }
        
        // create a 2d array with all not transparent and foreground blocks added
        boolean[][] tiles = new boolean[end - start][endY - startY];
        for (Chunk chunk : chunks) {
            for (Block block : chunk.blocks) {
                if (!block.transparent && block.layer == 0) {
                    try {
                    tiles[(int) block.pos.x - start][(int) block.pos.y - startY] = true;
                    } catch (ArrayIndexOutOfBoundsException err) {
                        println(1);   
                    }
                }
            }
        }
        
        // create light array
        int[][] lighted = new int[end - start][endY - startY];
        /*for (int[] row : lighted) {
            Arrays.fill(row, 15);
        }*/
        
        for (int i = start; i < end; i++) {
            // light the world with sky blocks over the world
            IntVector lightSource = new IntVector(i - start, 0);
            fillSpace(lightSource, 15, tiles, lighted, true, true);
        }
        
        for (Chunk chunk : chunks) {
            for (Block block : chunk.blocks) {
                if (block.light > 0) {
                    // light the world with block
                    IntVector blockPos = new IntVector((int) block.pos.x - start, (int) block.pos.y - startY);
                    fillSpace(blockPos, block.light, tiles, lighted, true, false);
                }
            }
        }
        
        // go through all loaded blocks
        for (int i = start; i < end; i++) {
            for (int j = startY; j < endY; j++) {  
                // only draw light if it's within the screen
                PVector screenPos = coordToPos(new PVector(i, j));
                
                if (camera.inScreen(new Hitbox(screenPos, blockSize))) {         
                    // determine blight from array
                    int lightLevel = lighted[i - start][j - startY];
                    
                    // calculate opacity from light level and limit to 253
                    int opacity = (15 - lightLevel) * 17;
                    if (opacity > 252) {
                        opacity = 252;
                    }
                    
                    // draw partly transparent black rect
                    fill(0, 0, 0, opacity);
                    noStroke();
                    rect(screenPos.x, screenPos.y, blockSize, blockSize);
                }
            }
        }
    }
    
    // return light loss on different sections of the day
    int lightLoss() {
        if (game.dayCycle < 600000) {
            // noon: 0
            return 0;
        } else if (game.dayCycle < 650000) {
            // sunset: 0 to -11
            return -(int)((game.dayCycle - 600000) / 50000 * 11);
        } else if (game.dayCycle < 1150000) {
            // night: -11
            return -11;
        } else {
            // sunrise: -11 to 0
            return -(int)((1200000 - game.dayCycle) / 50000 * 11);
        }
    }
    
    void saveChunk(Chunk chunk) {
        // save chunk if it hasn't been saved already
        if (!savedChunks.contains(chunk)) {
            savedChunks.add(chunk);
        }
    }
    
    void move() {
        // move every chunk
        for (Chunk chunk : chunks) {
            chunk.move();   
        }
    }
    
    void draw() { 
        // draw every chunk
        for (Chunk chunk : chunks) {
            chunk.drawWorld();   
        }
        
        for (Chunk chunk : chunks) {
            chunk.drawMobs();   
        }
    }
}
