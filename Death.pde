// class for death menu
class Death extends State {  
    // calculate button scale
    int scale = width / 3 / 200;
    
    // load font for labels
    PFont bigFont = createFont("Minecraftia.ttf", scale * 21);
    PFont myFont = createFont("Minecraftia.ttf", scale * 7);
    
    // create button
    IntVector buttonPos = new IntVector(width/2, height/2);
    IntVector buttonSize = new IntVector(200 * scale, 20 * scale);
    Button button = new Button("Respawn", buttonPos, buttonSize, myFont);
    
    void drawMenu() {
        // draw button
        button.draw();
    }
    
    void checkMenu() {
        if (button.check()) {
            // if button was clicked: respawn player
            player.spawn();
            changeState(game);
        }
    }
    
    void loop() {
        // draw and move world through game, draw inventory
        game.drawWorld();
        drawMenu();
        
        game.moveWorld();
        checkMenu();
    }
}
