// import packages
import java.util.Random;
import java.util.List;
import java.util.Arrays;
import java.util.Map;

// set blockSize and chunkSize
int blockSize = 100;
int chunkX = 4;

// initialize block and item data
String[] blockData;
String[] itemData;
String[] mobData;

// initialize font and textures
PFont numFont;
Map<String, PImage> textures = new HashMap<String, PImage>();

// initialize game and state
Game game;
State state;

// generate new world seed and noise
int seed = (int)random(10000, 1000000);
SNoise noise = new SNoise(seed);

// initialize objects
World world;
Player player;
Actions actions;
Camera camera;

// initialize keys and mouse
Map<Character, Boolean> pressedKeys = new HashMap<Character, Boolean>();
Map<Integer, Boolean> pressedCodes = new HashMap<Integer, Boolean>();
char[] keys = {'w', 'a', 'd'};
int[] codes = {SHIFT};

boolean leftMouse = false;
boolean rightMouse = false;

// initialize ArrayLists of all block, item and mob names
List<String> blockNames = new ArrayList<String>();
List<String> itemNames = new ArrayList<String>();
List<String> mobNames = new ArrayList<String>();

// create crafting recipes
List<Recipe> recipes = new ArrayList<Recipe>();
List<Item> products = new ArrayList<Item>();
Map<List<String>, String> craftingGroups = new HashMap<List<String>, String>();

// create smelting recipes
Map<String, Item> smeltingRecipes = new HashMap<String, Item>();
Map<String, Float> fuels = new HashMap<String, Float>();

// create food data
Map<String, Float> foodPoints = new HashMap<String, Float>();
Map<String, Float> foodSaturation = new HashMap<String, Float>();

PVector mouse = new PVector(0, 0);

PVector coordToPos(PVector coord) {
    // convert coordinates to screen position pased on player pos, blockSize, window center and player size
    float screenX = (coord.x - player.pos.x) * blockSize + (width / 2) - player.imWidth / 2;
    float screenY = (coord.y - player.pos.y) * blockSize + (height / 2) - player.imHeight / 2;
    
    return new PVector(screenX, screenY);
}

PVector posToCoord(PVector pos) {
    // convert screen position to coordinates pased on player pos, blockSize, window center and player size and camera
    float coordX = (pos.x + camera.x - (width / 2 - player.imWidth / 2)) / blockSize + player.pos.x;
    float coordY = (pos.y + camera.y - (height / 2 - player.imHeight / 2)) / blockSize + player.pos.y;
    
    return new PVector(coordX, coordY);
}

// load food data
void loadFood() {
    // create reader
    Reader reader = new Reader(loadStrings("data\\food.txt"));
    
    // loop through lines
    while (reader.hasNextLine()) {
        // split line and save health and saturation
        String[] lineSplit = reader.splitLine(" ");
        foodPoints.put(lineSplit[0], Float.parseFloat(lineSplit[1]));
        foodSaturation.put(lineSplit[0], Float.parseFloat(lineSplit[2]));
    }
}

void loadNames() {
    // load block/item/mob names
    CategoryReader reader = new CategoryReader(blockData, null);
    blockNames = reader.getCategories();
    
    reader = new CategoryReader(itemData, null);
    itemNames = reader.getCategories();
    
    reader = new CategoryReader(mobData, null);
    mobNames = reader.getCategories();
}

void loadTextures() {
    // load block/item/mob textures
    for (String block : blockNames) {
        textures.put(block, loadImage("blocks\\" + block + ".png"));
    }
    
    for (String item : itemNames) {
        textures.put(item, loadImage("items\\" + item + ".png"));
    }
    
    for (String mob : mobNames) {
        textures.put(mob, loadImage("mobs\\" + mob + ".png"));
    }
    
    // load breaking textures
    for (int i = 0; i < 10; i++) {
        textures.put("destroy_" + i, loadImage("blocks\\destroy_" + i + ".png"));   
    }
    
    // load lit furnace image
    textures.put("furnace_lit", loadImage("blocks\\furnace_lit.png"));
    
    // load inventory textures
    textures.put("hotbar", loadImage("gui\\hotbar.png"));
    textures.put("select", loadImage("gui\\select.png"));
    textures.put("inventory", loadImage("gui\\inventory.png"));
    textures.put("crafting", loadImage("gui\\crafting.png"));
    textures.put("chest_menu", loadImage("gui\\chest_menu.png"));
    
    // load furnace textures
    PImage furnaceMenu = loadImage("gui\\furnace_menu.png");
    textures.put("furnace_menu", furnaceMenu.get(0, 0, 176, 166));
    textures.put("burning", furnaceMenu.get(176, 0, 14, 14));
    textures.put("arrow", furnaceMenu.get(176, 14, 24, 17));
    
    // load skin textures from official skin structure
    PImage skin = loadImage("skins\\steve.png");
    
    // load head with overlay
    PImage head = skin.get(16, 8, 8, 8);
    PImage overlay = skin.get(46, 8, 8, 8);
    
    for (int i = 0; i < 8; i++) {
        for (int j = 0; j < 8; j++) {
            int pixel = overlay.get(i, j);
            if (alpha(pixel) == 255) {
                head.set(i, j, pixel);
            }
        }
    }
    textures.put("head", head);
    
    textures.put("body", skin.get(28, 20, 4, 12));
    textures.put("arm1", skin.get(40, 20, 4, 12));
    textures.put("arm2", skin.get(48, 20, 4, 12));
    textures.put("leg1", skin.get(16, 52, 4, 12));
    textures.put("leg2", skin.get(24, 52, 4, 12));
    
    // load all icons
    PImage icons = loadImage("gui\\icons.png");
    textures.put("empty_heart", icons.get(0, 0, 9, 9));
    textures.put("half_heart", icons.get(9, 0, 9, 9));
    textures.put("full_heart", icons.get(18, 0, 9, 9));
    textures.put("empty_heart_bland", icons.get(27, 0, 9, 9));
    textures.put("half_heart_bland", icons.get(36, 0, 9, 9));
    textures.put("full_heart_bland", icons.get(45, 0, 9, 9));
    
    textures.put("empty_food", icons.get(0, 18, 9, 9));
    textures.put("half_food", icons.get(9, 18, 9, 9));
    textures.put("full_food", icons.get(18, 18, 9, 9));
    
    // load button
    PImage button = loadImage("gui\\button.png");
    textures.put("button", button.get(0, 0, 200, 20));
    textures.put("targeted_button", button.get(0, 20, 200, 20));
}

// load crafting recipes
void loadRecipes() {
    // create reader object
    Reader reader = new Reader(loadStrings("data\\recipes.txt"));
    
    // recipe - current recipe, lineNr - line of recipe
    Recipe recipe = null;
    int lineNr = 0;
    
    // loop throught recipes.txt
    while (reader.hasNextLine()) {
        if (lineNr == 0) {
            // get recipe size and create new recipe based on size
            String[] lineSplit = reader.splitLine("x");
            recipe = new Recipe(Integer.valueOf(lineSplit[1]), Integer.valueOf(lineSplit[0]));
            lineNr++;
        } else {
            String[] lineSplit = reader.splitLine(" ");
            
            if (lineNr <= recipe.rows) {
                // if line is part of crafting recipe add it to the recipe
                recipe.setRow(lineNr - 1, lineSplit);
                lineNr++;
            } else {
                // else get the product and add recipe and product to the ArrayLists
                Item productItem = new Item(lineSplit[1], Integer.valueOf(lineSplit[0]));
                recipes.add(recipe);
                products.add(productItem);
                
                // reset line
                lineNr = 0;
            }
        }
    }
    
    // create reader object
    reader = new Reader(loadStrings("data\\crafting_groups.txt"));
    
    // loop through crafting_groups.txt
    while (reader.hasNextLine()) {
        // get all crafting group members and the group name
        String[] lineSplit = reader.splitLine(" -> ");
        List<String> input = Arrays.asList(lineSplit[0].split(" "));
        
        // put it into crafting groups
        craftingGroups.put(input, lineSplit[1]);
    }
}

void loadFurnaceData() {
    // create reader object
    Reader reader = new Reader(loadStrings("data\\smelting_recipes.txt"));
    
    // loop through file
    while (reader.hasNextLine()) {
        // put items split by arrow into smelting recipes
        String[] lineSplit = reader.splitLine(" -> ");
        Item product = new Item(lineSplit[1], 1);
        
        smeltingRecipes.put(lineSplit[0], product);
    }
    
    // create reader object
    reader = new Reader(loadStrings("data\\fuels.txt"));
    
    // loop through file
    while (reader.hasNextLine()) {
        // put values split by space into fuels
        String[] lineSplit = reader.splitLine(" ");
        Float durability = Float.valueOf(lineSplit[1]);
        
        fuels.put(lineSplit[0], durability);
    }
}

void settings() {
    // set window to fullscreen
    fullScreen(P2D);
    noSmooth();
    
    // set icon to grass block
    PJOGL.setIcon("blocks\\grass_block.png");
}

void setup() { 
    // set noise seed to seed
    noiseSeed(seed);
    frameRate(60);
    
    // load block/item details and images
    blockData = loadStrings("data\\block_data.txt");
    itemData = loadStrings("data\\item_data.txt");
    mobData = loadStrings("data\\mob_data.txt");
    
    // load block/item names, textures, recipes, furnace data
    loadNames();
    loadTextures();
    loadFood();
    loadRecipes();
    loadFurnaceData();
    
    // create world, player and camera
    world = new World();
    // create chunks around spawn
    world.updateChunks(world.getSpawn().x);   
        
    player = new Player();
    actions = new Actions();
    player.spawn();
    camera = new Camera();
    
    // set the start state to game
    game = new Game();
    state = game;
    
    // initialize pressed keys
    for (char ch : keys) {
        pressedKeys.put(ch, false);   
    }
    
    for (int n : codes) {
        pressedCodes.put(n, false);   
    }
    
    // load font
    numFont = createFont("Minecraftia.ttf", 15);
    
    // disable anti-aliasing for pixels
    ((PGraphicsOpenGL)g).textureSampling(2);
    
    // set cursor type
    cursor(CROSS);
    
    // set window title and icon
    surface.setTitle("2D Minecraft");
}

void draw() {
    // let the state loop
    state.loop();  
}

void changeState(State newState) {
    // change current state
    state.finish();
    state = newState;
    state.start();
}

// change pressedKeys
void keyPressed() {
    // pass event to state
    state.keyPressed();
    
    setKey(true);
}

void keyReleased() {
    setKey(false);
}

// change mouse button presses
void mousePressed() {
    // pass the event to the state
    state.mousePressed();
    
    setMouse(true);
}

void mouseReleased() {
    // pass the event to the state
    state.mouseReleased();
    
    setMouse(false);  
}

void mouseDragged() {
    // pass event to state
    state.mouseDragged();   
}

void mouseWheel(MouseEvent event) {
    state.mouseWheel(event.getCount());
}

void setKey(boolean b) {
    // change pressedKeys and pressedCodes based on pressed or released key
    if (key == CODED) {
       for (int code : codes) {
            if (code == keyCode) {
                pressedCodes.put(code, b);
                break;
            }
        }    
    } else {
        for (char k : keys) {
            if (k == Character.toLowerCase(key)) {
                pressedKeys.put(k, b);
                break;
            }
        }  
    }
}

void setMouse(boolean b) {
    // change mouse button state based on clicks and releases
    if (mouseButton == LEFT) {
        leftMouse = b;
    } else {
        rightMouse = b;
    }
}
