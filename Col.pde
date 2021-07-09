// class for collection of items
class Collection {
    Item[][] items;
    int rows, cols;
    
    Collection(int rows, int cols, String type) {
        // initialize rows and columns and array of items
        this.rows = rows;
        this.cols = cols;
        
        items = new Item[rows][cols];
        
        // add empty items (items with count 0)
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                items[i][j] = new Item(null, 0, type);
            }
        }
    }
    
    // default type if no type given
    Collection(int rows, int cols) {
        this(rows, cols, "all");   
    }
    
    void add(Item item) {  
        // add item to every item of the collection (if filled slot)
        for (Item[] row : items) {
            for (Item i : row) {
                if (i.count > 0) {
                    i.add(item, 64);
                }
            }
        }
    }
    
    void fill(Item item) {
        // add item to every item of the collection (if empty slot)
        for (Item[] row : items) {
            for (Item i : row) {
                if (i.count == 0) {
                    i.add(item, 64);
                }
            }
        }
    }
    
    Collection copy() {
        Collection result = new Collection(rows, cols);
        
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                result.items[i][j] = items[i][j].copy();
            }
        }
        
        return result;
    }
    
    // load collection to avoid identity issues
    void load(Collection col) {
        if (rows == col.rows && cols == col.cols) {
            // load every item
            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < cols; j++) {
                    items[i][j] = col.items[i][j].copy();
                }
            }
        } else {
            // throw exception if mismatched sizes
            throw new RuntimeException("Collection sizes do not match"); 
        }
    }
    
    Item item() {
        // return first item if collection is a single item
        if (rows == 1 && cols == 1) {
            return items[0][0];  
        } else {
            throw new RuntimeException("Collection isn't a single item");
        }
    }
    
    // get index of item based on position of mouse
    IntVector getPos(PVector pos, PVector start, int itemSize) {
        // normalize position based on top left corner and itemSize
        int itemX = floor((pos.x - start.x) / itemSize);
        int itemY = floor((pos.y - start.y) / itemSize);
        
        // return null if position is outside the collection
        if (itemX < 0 || itemX >= cols || itemY < 0 || itemY >= rows) {
            return null; 
        } else {
            return new IntVector(itemY, itemX);  
        }
    }
    
    // get item based on index
    Item get(IntVector pos) {
        return items[pos.x][pos.y];
    }
        
    // set item based on index
    void set(IntVector pos, Item item) {
        items[pos.x][pos.y] = item;   
    }
    
    void draw(PVector pos, int itemSize) {
        // draw all items
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                if (items[i][j] != null) {
                    // calculate item pos based on item size
                    PVector itemPos = new PVector(pos.x + j * itemSize, pos.y + i * itemSize);
                    items[i][j].draw(itemPos, itemSize, false);
                }
            }
        }
    }
}
