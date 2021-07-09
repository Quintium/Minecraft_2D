// class for crafting recipes
class Recipe {
    int cols;
    int rows;
    
    String[][] items;
    
    // create new crafting recipe with rows and cols
    Recipe(int rows, int cols) {
        this.rows = rows;
        this.cols = cols;
        items = new String[rows][cols];
    }
    
    // replace row with array
    void setRow(int n, String[] row) {
        items[n] = row;
    }
    
    // check if crafting ingredients match with recipe
    boolean compare(Collection col) {
        // check for all possible recipe offsets
        for (int i = 0; i <= col.rows - rows; i++) {
            for (int j = 0; j <= col.cols - cols; j++) {
                int correct = 0;
                
                // get hitbox of recipe within crafting table
                Hitbox recipeHitbox = new Hitbox(j, i, cols, rows);
                
                for (int y = 0; y < col.rows; y++) {
                    for (int x = 0; x < col.cols; x++) {
                        Item item = col.items[y][x];
                        
                        boolean correctItem;
                        Hitbox itemHitbox = new Hitbox(x, y, 1, 1);
                        
                        if (recipeHitbox.overlap(itemHitbox)) {
                            // correct item is either (not empty, name equals name of recipe item) or (empty and recipe item is "none")
                            correctItem = compareItems(items[y - i][x - j], item);
                        } else {
                            // if item is outside of recipe, correct item is empty item
                            correctItem = item.count == 0;
                        }
                        
                        // change correct if item is correct
                        correct += correctItem ? 1 : 0;
                    }
                }
                
                // if all items are correct return true
                if (correct == col.cols * col.rows) {
                    return true;   
                }
            }
        }
        
        return false;
    }
    
    // compare if string and item match
    boolean compareItems(String s, Item item) {
        if (item.count == 0) {
            // return true if item is empty and string is none
            return s.equals("none");
        } else {
            // return true if item name is in group s
            for (List<String> group : craftingGroups.keySet()) {
                if (group.contains(item.name) && s.equals(craftingGroups.get(group))) {
                    return true;
                }
            }
            
            // return true if item name is equal to s
            return s.equals(item.name);
        }
    }
}
