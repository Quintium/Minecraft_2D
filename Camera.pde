class Camera {
    int x = 0;
    int y = 0;
    
    void update() {
        // calculate camera change based on cursor position
        x = (int)((float)(mouseX - width / 2) * blockSize / 1000);
        y = (int)((float)(mouseY - height / 2) * blockSize / 1000);
    }
    
    // translate camera pos and change mouse
    void activate() {
        translate(-x, -y);
        mouse.x = mouseX + x;
        mouse.y = mouseY + y;
    }
    
    // translate canvas back
    void deactivate() {
        translate(x, y);   
        mouse.x = mouseX;
        mouse.y = mouseY;
    }
    
    // return screen hitbox
    Hitbox getHitbox() {
        return new Hitbox(x, y, width, height);   
    }
    
    // return if hitbox overlaps with screen
    boolean inScreen(Hitbox h) {
        return getHitbox().overlap(h);
    }
}
