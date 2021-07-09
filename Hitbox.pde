class Hitbox {
    float left;
    float right;
    float top;
    float bottom;
    
    Hitbox(float x, float y, float len, float wid) {
        // calculate sides of hitbox
        left = x;
        right = x + len;
        top = y;
        bottom = y + wid;
    }
    
    Hitbox(PVector v, float size) {
        // create hitbox from vector
        this(v.x, v.y, size, size);   
    }
    
    Hitbox(IntVector v, float size) {
        // create hitbox from vector
        this(v.x, v.y, size, size);   
    }
    
    boolean overlap(Hitbox hitbox) {
        // calculate if hitboxes overlap
        if (left >= hitbox.right || hitbox.left >= right) {
            return false;   
        }
        
        if (top >= hitbox.bottom || hitbox.top >= bottom) {
            return false;   
        }
        
        return true;
    }
}
