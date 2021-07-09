// class for handling interactions between collections, e.g.

class CollectionInteraction {
    Collection[] collections;
    PVector[] positions;
    int itemSize;
    Hitbox hitbox;
    Collection product;
    Pointer[] pointers;
    
    // initialize vars for dragging
    List<IntVector> draggedPos = new ArrayList<IntVector>();
    Collection[] colsCopy;
    Item itemCopy;
    
    Item grabbedItem = new Item(null, 0);
    
    CollectionInteraction(Collection[] collections, PVector[] positions, Pointer[] pointers, Collection product, int itemSize, Hitbox hitbox) {
        /* initialize: - collections: array of collections
                       - positions: array of positions of the collections
                       - pointers: pointers from collection to collection for shift clicking
                       - product: collection index which can't be replaced
                       - item size: size of items when drawn
                       - hitbox: hitbox of the whole collection interaction
        */
        
        this.collections = collections;
        this.positions = positions;
        this.pointers = pointers;
        this.product = product;
        this.itemSize = itemSize;
        this.hitbox = hitbox;
    }
    
    // update dragged items
    void dragged() {
        if (draggedPos.size() > 0) {
            for (int i = 0; i < collections.length; i++) {
                Collection col = collections[i];
                // get index at mouse pos
                IntVector pos = col.getPos(mouse, positions[i], itemSize);
                
                // if there's an item, get it
                if (pos != null) {
                    IntVector colPos = new IntVector(pos.x, pos.y, i);
                    
                    // check if item pos is already in dragged pos to avoid duplicate dragging
                    boolean found = false;
                    for (IntVector pv : draggedPos) {
                        if (pv.equals(colPos)) {
                            found = true;
                        }
                    }
                    
                    // add pos if item pos hasn't been found and item type matches
                    if (!found && itemCopy.matches(col.get(pos)) && col != product) {
                        draggedPos.add(colPos);
                    }
                    
                    break;
                }    
            }  
            
            // load collections copy
            for (int i = 0; i < collections.length; i++) {
                // don't load if collection is product (to avoid crafting issues)
                if (collections[i] != product) {
                    collections[i].load(colsCopy[i]);
                }
            }
            
            // load item copy
            grabbedItem = itemCopy.copy();
            
            if (mouseButton == LEFT) {
                // distribute items if left mouse button with min of 1
                int distributed = grabbedItem.count / draggedPos.size();
                if (distributed == 0) {
                    distributed = 1;
                }
                
                for (IntVector pos : draggedPos) {
                    collections[pos.z].get(pos).add(grabbedItem, distributed);
                }
            } else {
                // add one if right mouseButton   
                for (IntVector pos : draggedPos) {
                    collections[pos.z].get(pos).add(grabbedItem, 1);
                }
            }
        } 
    }
    
    // actions when mouse is clicked
    void clicked() {
        // if item not dragged, grab item or start to drag
        if (draggedPos.size() == 0) {
            // loop through collections 
            for (int i = 0; i < collections.length; i++) {
                Collection col = collections[i];
                // get index at mouse pos
                IntVector pos = col.getPos(mouse, positions[i], itemSize);
                
                // if there's an item, get it
                if (pos != null) {
                    Item item = col.get(pos);
                    
                    if (grabbedItem.count == 0) {
                        // add item to grabbedItem, (64 means all)
                        grabbedItem.add(item, 64);
                    } else {         
                        if (col != product) {
                            // start dragging
                            IntVector colPos = new IntVector(pos.x, pos.y, i);
                            startDrag(colPos);
                        }
                    }
                    
                    break;
                }       
            }
        } else {
            // reset drag if mouse clicked while dragging
            
            // load collections copy
            for (int i = 0; i < collections.length; i++) {
                // don't load if collection is product (to avoid crafting issues)
                if (collections[i] != product) {
                    collections[i].load(colsCopy[i]);
                }
            }
            
            // load item copy
            grabbedItem = itemCopy.copy();
        }
            
        // if mouse click is outside the hitbox, drop item, (64 means all)
        Hitbox m = new Hitbox(mouse, 0);
        if (!m.overlap(hitbox)) {
            actions.drop(grabbedItem, 64);
        }
    }
    
    // finish dragging when mouse released
    void released() {
        // if dragging
        if (draggedPos.size() > 0) {
            // if only one item is clicked
            if (draggedPos.size() == 1) {
                IntVector pos = draggedPos.get(0);
                Item item = collections[pos.z].get(pos);
                // check if grabbed and highlighted item don't match
                if (!item.matches(grabbedItem)) {
                    // switch the two items
                    Item savedItem = item.copy(); //<>//
                    item.loadItem(grabbedItem);
                    grabbedItem.loadItem(savedItem); //<>// //<>//
                }
            }
            
            draggedPos = new ArrayList<IntVector>();   
        }
    }
    
    // actions when mouse with shift is clicked
    void shiftClicked() {
        // loop through collections
        for (int i = 0; i < collections.length; i++) {
            Collection col = collections[i];
            // get index at mouse pos
            IntVector pos = col.getPos(mouse, positions[i], itemSize);
            
            // if there's an item, get it
            if (pos != null) {
                Item item = col.get(pos);
         
                // loop through pointers
                for (Pointer pointer : pointers) {
                    // loop through pointer ends (only if start is current collection)
                    for (Collection end : pointer.getEnds(col)) {
                        // add item to destination
                        end.add(item);
                        end.fill(item);
                    }
                }
                
                break;
            }       
        }
            
        // if mouse click is outside the hitbox, drop item, (64 means all)
        Hitbox m = new Hitbox(mouse, 0);
        if (!m.overlap(hitbox)) {
            actions.drop(grabbedItem, 64);
        }
    }
    
    // actions when mouse is right clicked
    void rightClicked() {
        // if not dragged complete actions
        if (draggedPos.size() == 0) {
            // loop through collections
            for (int i = 0; i < collections.length; i++) {
                Collection col = collections[i];
                
                // get index at mousePos
                IntVector pos = col.getPos(mouse, positions[i], itemSize);
                
                // if there's an item
                if (pos != null) {
                    // if no item is grabbed
                    if (grabbedItem.count == 0) {
                        // add half of the item to grabbedItem
                        Item item = col.get(pos);
                        grabbedItem.add(item, floor(item.count / 2));
                    } else {
                        if (col != product) {
                            // start dragging
                            IntVector colPos = new IntVector(pos.x, pos.y, i);
                            startDrag(colPos);
                        }
                    }
                    
                    break;
                }
            }
        } else {
            // load collections copy
            for (int i = 0; i < collections.length; i++) {
                // don't load if collection is product (to avoid crafting issues)
                if (collections[i] != product) {
                    collections[i].load(colsCopy[i]);
                }
            }
            
            // load item copy
            grabbedItem = itemCopy.copy();
        }
        
        // if click is outside of hitbox, drop one item
        Hitbox m = new Hitbox(mouse, 0);
        if (!m.overlap(hitbox)) {              
            actions.drop(grabbedItem, 1);
        }
    }
    
    void startDrag(IntVector colPos) {
        draggedPos.add(colPos);
                    
        // copy collections and item
        colsCopy = new Collection[collections.length];
        for (int j = 0; j < collections.length; j++) {
            colsCopy[j] = collections[j].copy();
        }
        itemCopy = grabbedItem.copy();
        
        dragged();
    }
    
    // drop grabbed item when finished
    void finish() {
        actions.drop(grabbedItem, 64);
    }
    
    void draw() {
        // draw selected slot
        for (int i = 0; i < collections.length; i++) {
            // check if mouse is in any slot
            IntVector pos = collections[i].getPos(mouse, positions[i], itemSize);
            if (pos != null) {
                // light gray fill
                fill(200);
                noStroke();
                
                // flip pos
                PVector drawPos = new PVector(pos.y, pos.x);
                
                // multiply pos by item size, add position, add big pixel (to be in the middle of the slot)
                float pixel = itemSize / 18;
                drawPos.mult(itemSize);
                drawPos.add(positions[i]);
                drawPos.add(pixel, pixel);
                
                // draw rect
                rect(drawPos.x, drawPos.y, itemSize - 2 * pixel, itemSize - 2 * pixel);
            }
        }
        
        // draw every collection at each position
        for (int i = 0; i < collections.length; i++) {
            collections[i].draw(positions[i], itemSize);   
        }
        
        // draw grabbedItem
        grabbedItem.draw(mouse, itemSize, true);
    }
}

// pointer from collection to multiple collections
class Pointer {
    Collection start;
    Collection[] ends;
    
    // pointer with variable amount of ends
    Pointer(Collection start, Collection... ends) {
        this.start = start;
        this.ends = ends;
    }
    
    Collection[] getEnds(Collection input) {
        if (input == start) {
            // return all ends if input matches start
            return ends;
        } else {
            // else return empty array
            return new Collection[0];
        }
    }
}
