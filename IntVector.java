// class for vectors with ints
public class IntVector {
    int x, y, z;
    
    // constructors for 2d and 3d vectors
    public IntVector(int x, int y) {
        this.x = x;
        this.y = y;
        this.z = 0;
    }
    
    public IntVector(float x, float y) {
        this.x = (int)x;
        this.y = (int)y;
        this.z = 0;
    }
    
    public IntVector(int x, int y, int z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }
    
    
    // instance operations
    void add(IntVector v) {
        x += v.x;
        y += v.y;
        z += v.z;
    }
    
    void sub(IntVector v) {
        x -= v.x;
        y -= v.y;
        z -= v.z;
    }
    
    void mult(int n) {
        x *= n;
        y *= n;
        z *= n;
    }
    
    void div(int n) {
        x /= n;
        y /= n;
        z /= n;
    }
    
    
    // static operations
    static IntVector add(IntVector v1, IntVector v2) {
        return new IntVector(v1.x + v2.x, v1.y + v2.y, v1.z + v2.z);
    }
    
    static IntVector sub(IntVector v1, IntVector v2) {
        return new IntVector(v1.x - v2.x, v1.y - v2.y, v1.z - v2.z);
    }
    
    static IntVector mult(IntVector v, int n) {
        return new IntVector(v.x * n, v.y * n, v.z * n);
    }
    
    static IntVector div(IntVector v, int n) {
        return new IntVector(v.x / n, v.y / n, v.z / n);
    }
    
    
    // equals function
    boolean equals(IntVector v) {
        return x == v.x && y == v.y && z == v.z;   
    }
    
    // copy vector
    IntVector copy() {
        return new IntVector(x, y, z);   
    }
}
