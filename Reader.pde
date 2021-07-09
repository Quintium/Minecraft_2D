// class for reading and splitting txt files
class Reader {
    ArrayList<String> data = new ArrayList<String>();;
    private int lineNr = 0;
    
    Reader(String[] data) {
        // convert array to arrayList and erase empty lines
        for (String s : data) {
            if (! s.isEmpty()) {
                this.data.add(s);
            }
        }
    }
    
    // return if there's a next line
    boolean hasNextLine() {
        return lineNr < data.size();
    }
    
    String[] splitLine(String s) {
        // split line by a string
        String[] line = data.get(lineNr).split(s);
        
        // increase line count and return
        lineNr++;
        return line;
    }
}

// class for getting information from categories in txt file
class CategoryReader extends Reader {
    private String category;
    private ArrayList<String> categories = new ArrayList<String>();
    
    CategoryReader(String[] data, String category) {
        // initialize reader class and manage categories
        super(data);
        this.category = category;
        removeCategories();
    }
    
    // remove all other categories
    void removeCategories() {
        ArrayList<String> newData = new ArrayList<String>();
        // current category in txt file
        String currentCategory = null;
        
        // loop through data
        for (String line : data) {
            // if line contains ':'
            if (line.indexOf(':') != -1) {
                // change category, add it to categories
                currentCategory = line.split(":")[0];
                categories.add(currentCategory);
            } else if (currentCategory.equals(category)) {
                // remove two spaces at the beginning and add to new data
                newData.add(line.substring(2, line.length()));
            }
        }
        
        // replace data
        data = newData;
    }
    
    ArrayList getCategories() {
        return categories;
    }
}
